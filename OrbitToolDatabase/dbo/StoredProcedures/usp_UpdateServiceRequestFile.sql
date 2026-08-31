/*
    Stored Procedure: usp_UpdateServiceRequestFile
    Description: Updates an existing service request file with audit logging.
*/
CREATE PROCEDURE [dbo].[usp_UpdateServiceRequestFile]
    @FileId INT,
    @Name NVARCHAR(250) = NULL,
    @FileFormat VARCHAR(10) = NULL,
    @CompressedData VARBINARY(MAX) = NULL,
    @UncompressedSizeBytes INT = NULL,
    @CompressionAlgorithmType VARCHAR(50) = NULL,
    @ContentHash VARCHAR(64) = NULL,
    @IsActive BIT = NULL,
    @UserId NVARCHAR(20) = NULL,
    @RecordVersion VARCHAR(50)  -- For optimistic concurrency control
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LocalTranStarted BIT = 0;
    IF @@TRANCOUNT = 0
    BEGIN
        BEGIN TRANSACTION;
        SET @LocalTranStarted = 1;
    END

    BEGIN TRY
        DECLARE @ResolvedUser NVARCHAR(20);
        DECLARE @NewRecordVersion VARCHAR(50);
        DECLARE @ActivityId BIGINT;
        DECLARE @Notes NVARCHAR(MAX);
        DECLARE @ExistingRecordVersion VARCHAR(50);
        DECLARE @ExistingName NVARCHAR(250);
        DECLARE @ExistingFileFormat VARCHAR(10);
        DECLARE @ExistingCompressedData VARBINARY(MAX);
        DECLARE @ExistingUncompressedSizeBytes INT;
        DECLARE @ExistingCompressionAlgorithmType VARCHAR(50);
        DECLARE @ExistingContentHash VARCHAR(64);
        DECLARE @ExistingIsActive BIT;
        DECLARE @OperationName NVARCHAR(200);
        DECLARE @ServiceName NVARCHAR(200);
        DECLARE @ServiceAppPublicId UNIQUEIDENTIFIER;
        DECLARE @ServiceOperationId INT;
        DECLARE @CalculatedHash VARCHAR(64);
        DECLARE @ContentChanged BIT = 0;
        DECLARE @MetadataChanged BIT = 0;
        DECLARE @StatusChanged BIT = 0;

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Get the current file details with lock
        SELECT TOP 1
            @ExistingRecordVersion = [RecordVersion],
            @ExistingName = [Name],
            @ExistingFileFormat = [FileFormat],
            @ExistingCompressedData = [CompressedData],
            @ExistingUncompressedSizeBytes = [UncompressedSizeBytes],
            @ExistingCompressionAlgorithmType = [CompressionAlgorithmType],
            @ExistingContentHash = [ContentHash],
            @ExistingIsActive = [IsActive],
            @ServiceOperationId = [ServiceOperationId]
        FROM [dbo].[ServiceRequestFiles] WITH (UPDLOCK, HOLDLOCK)
        WHERE [Id] = @FileId;

        IF @FileId IS NULL OR @ServiceOperationId IS NULL
        BEGIN
            RAISERROR('Service request file with Id %d not found.', 16, 1, @FileId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Get operation and service details
        SELECT 
            @OperationName = so.[OperationName],
            @ServiceName = sa.[Name],
            @ServiceAppPublicId = sa.[PublicId]
        FROM [dbo].[ServiceOperations] so
        INNER JOIN [dbo].[ServiceApplications] sa ON so.[ServiceApplicationId] = sa.[Id]
        WHERE so.[Id] = @ServiceOperationId;

        -- Concurrency check
        IF @ExistingRecordVersion != @RecordVersion
        BEGIN
            RAISERROR('Record has been modified by another user. Current version: %s. Please refresh and try again.', 16, 1, @ExistingRecordVersion);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Detect changes
        IF @CompressedData IS NOT NULL AND @CompressedData <> @ExistingCompressedData
        BEGIN
            SET @ContentChanged = 1;
            
            -- Calculate hash if not provided
            IF @ContentHash IS NULL
            BEGIN
                SET @CalculatedHash = CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', @CompressedData), 2);
            END
            ELSE
            BEGIN
                SET @CalculatedHash = @ContentHash;
            END
        END
        ELSE
        BEGIN
            SET @CalculatedHash = @ExistingContentHash;
        END

        IF @Name IS NOT NULL AND @Name <> @ExistingName
            SET @MetadataChanged = 1;

        IF @FileFormat IS NOT NULL AND @FileFormat <> @ExistingFileFormat
            SET @MetadataChanged = 1;

        IF @UncompressedSizeBytes IS NOT NULL AND @UncompressedSizeBytes <> @ExistingUncompressedSizeBytes
            SET @MetadataChanged = 1;

        IF @CompressionAlgorithmType IS NOT NULL AND @CompressionAlgorithmType <> @ExistingCompressionAlgorithmType
            SET @MetadataChanged = 1;

        IF @IsActive IS NOT NULL AND @IsActive <> @ExistingIsActive
            SET @StatusChanged = 1;

        -- If nothing changed, return existing record
        IF @ContentChanged = 0 AND @MetadataChanged = 0 AND @StatusChanged = 0
        BEGIN
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                COMMIT TRANSACTION;

            SELECT 
                [Id] AS FileId,
                [ServiceOperationId],
                [FileFormat],
                [Name],
                [IsBaseSnapshot],
                [ParentBaseId],
                [ParentDeltaId],
                [DeltaDepth],
                [CompressedData],
                [UncompressedSizeBytes],
                [CompressionAlgorithmType],
                [ContentHash],
                [RecordVersion],
                [IsActive],
                [CreatedAt],
                [CreatedBy],
                [LastUpdatedAt],
                [LastUpdatedBy]
            FROM [dbo].[ServiceRequestFiles]
            WHERE [Id] = @FileId;
            
            RETURN;
        END

        -- Calculate new version
        SET @NewRecordVersion = [dbo].[fn_CalculateVersion](@ExistingRecordVersion);

        -- Update the record
        UPDATE [dbo].[ServiceRequestFiles]
        SET
            [Name] = ISNULL(@Name, [Name]),
            [FileFormat] = ISNULL(@FileFormat, [FileFormat]),
            [CompressedData] = ISNULL(@CompressedData, [CompressedData]),
            [UncompressedSizeBytes] = ISNULL(@UncompressedSizeBytes, [UncompressedSizeBytes]),
            [CompressionAlgorithmType] = ISNULL(@CompressionAlgorithmType, [CompressionAlgorithmType]),
            [ContentHash] = @CalculatedHash,
            [IsActive] = ISNULL(@IsActive, [IsActive]),
            [RecordVersion] = @NewRecordVersion,
            [LastUpdatedAt] = GETDATE(),
            [LastUpdatedBy] = @ResolvedUser
        WHERE [Id] = @FileId;

        -- Build notes
        SET @Notes = CONCAT('Service request file updated: ', ISNULL(@Name, @ExistingName), 
                           ' (Operation: ', @OperationName, ', Service: ', @ServiceName, ')');
        IF @ContentChanged = 1
            SET @Notes = CONCAT(@Notes, ' Content changed');
        IF @StatusChanged = 1
            SET @Notes = CONCAT(@Notes, ' Status: ', CASE WHEN @IsActive = 1 THEN 'Activated' ELSE 'Deactivated' END);

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Update' AS ChangeType,
                @FileId AS FileId,
                ISNULL(@Name, @ExistingName) AS FileName,
                @ExistingRecordVersion AS OldVersion,
                @NewRecordVersion AS NewVersion,
                @ContentChanged AS ContentChanged,
                @MetadataChanged AS MetadataChanged,
                @StatusChanged AS StatusChanged
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'ServiceRequestFileUpdate',
            @ActionType = 'Update',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'ServiceApplication',
            @RelatedEntityId = @ServiceAppPublicId,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the updated record
        SELECT 
            [Id] AS FileId,
            [ServiceOperationId],
            [FileFormat],
            [Name],
            [IsBaseSnapshot],
            [ParentBaseId],
            [ParentDeltaId],
            [DeltaDepth],
            [CompressedData],
            [UncompressedSizeBytes],
            [CompressionAlgorithmType],
            [ContentHash],
            [RecordVersion],
            [IsActive],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy],
            @ActivityId AS AuditActivityId
        FROM [dbo].[ServiceRequestFiles]
        WHERE [Id] = @FileId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error updating service request file: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO