/*
    Stored Procedure: usp_UpdateServiceRequestFileWithDeltaChain
    Description: Updates an existing request file by creating a new delta chain entry.
    The previous version is preserved as a delta record (IsBaseSnapshot = 0),
    and the active record is updated with the new payload.
*/
CREATE PROCEDURE [dbo].[usp_UpdateServiceRequestFileWithDeltaChain]
    @FileId INT,
    @CompressedData VARBINARY(MAX),
    @UncompressedSizeBytes INT = NULL,
    @CompressionAlgorithmType VARCHAR(50) = NULL,
    @ContentHash VARCHAR(64) = NULL,
    @BackwardDiffData VARBINARY(MAX) = NULL,
    @UserId NVARCHAR(20) = NULL
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
        DECLARE @CalculatedHash VARCHAR(64);
        DECLARE @ExistingRecordVersion VARCHAR(50);
        DECLARE @ExistingCompressedData VARBINARY(MAX);
        DECLARE @ExistingUncompressedSizeBytes INT;
        DECLARE @ExistingCompressionAlgorithmType VARCHAR(50);
        DECLARE @ExistingContentHash VARCHAR(64);
        DECLARE @ExistingIsBaseSnapshot BIT;
        DECLARE @ExistingParentBaseId INT;
        DECLARE @ExistingDeltaDepth INT;
        DECLARE @ExistingCreatedBy NVARCHAR(20);
        DECLARE @BaseId INT;
        DECLARE @OperationName NVARCHAR(200);
        DECLARE @ServiceName NVARCHAR(200);
        DECLARE @ServiceAppPublicId UNIQUEIDENTIFIER;
        DECLARE @ServiceOperationId INT;

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Get the current file details with lock
        SELECT TOP 1
            @ExistingRecordVersion = [RecordVersion],
            @ExistingCompressedData = [CompressedData],
            @ExistingUncompressedSizeBytes = [UncompressedSizeBytes],
            @ExistingCompressionAlgorithmType = [CompressionAlgorithmType],
            @ExistingContentHash = [ContentHash],
            @ExistingIsBaseSnapshot = [IsBaseSnapshot],
            @ExistingParentBaseId = [ParentBaseId],
            @ExistingDeltaDepth = [DeltaDepth],
            @ExistingCreatedBy = [CreatedBy],
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

        -- Calculate hash if not provided
        IF @ContentHash IS NULL AND @CompressedData IS NOT NULL
        BEGIN
            SET @CalculatedHash = CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', @CompressedData), 2);
        END
        ELSE
        BEGIN
            SET @CalculatedHash = @ContentHash;
        END

        -- Find the base snapshot ID for this delta chain
        SET @BaseId = COALESCE(@ExistingParentBaseId, @FileId);

        -- Create a delta record preserving the old version
        INSERT INTO [dbo].[ServiceRequestFiles] (
            [ServiceOperationId], [FileFormat], [Name],
            [IsBaseSnapshot], [ParentBaseId], [ParentDeltaId], [DeltaDepth],
            [CompressedData], [UncompressedSizeBytes],
            [CompressionAlgorithmType], [ContentHash],
            [RecordVersion], [IsActive],
            [CreatedAt], [CreatedBy]
        )
        VALUES (
            @ServiceOperationId,
            (SELECT [FileFormat] FROM [dbo].[ServiceRequestFiles] WHERE [Id] = @FileId),
            (SELECT [Name] FROM [dbo].[ServiceRequestFiles] WHERE [Id] = @FileId),
            0, -- Historical record
            @BaseId, @FileId, @ExistingDeltaDepth + 1,
            ISNULL(@BackwardDiffData, @ExistingCompressedData),
            @ExistingUncompressedSizeBytes,
            CASE WHEN @BackwardDiffData IS NOT NULL THEN NULL ELSE @ExistingCompressionAlgorithmType END,
            @ExistingContentHash,
            @ExistingRecordVersion,
            0, -- Inactive historical record
            GETDATE(), @ResolvedUser
        );

        -- Calculate new version
        SET @NewRecordVersion = [dbo].[fn_CalculateVersion](@ExistingRecordVersion);

        -- Update the active file record with new payload
        UPDATE [dbo].[ServiceRequestFiles]
        SET
            [CompressedData] = @CompressedData,
            [UncompressedSizeBytes] = @UncompressedSizeBytes,
            [CompressionAlgorithmType] = @CompressionAlgorithmType,
            [ContentHash] = @CalculatedHash,
            [RecordVersion] = @NewRecordVersion,
            [LastUpdatedAt] = GETDATE(),
            [LastUpdatedBy] = @ResolvedUser
        WHERE [Id] = @FileId;

        -- Build notes
        SET @Notes = CONCAT('Request file updated with delta chain: ', (SELECT [Name] FROM [dbo].[ServiceRequestFiles] WHERE [Id] = @FileId));

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Update' AS ChangeType,
                @FileId AS FileId,
                @ExistingRecordVersion AS OldVersion,
                @NewRecordVersion AS NewVersion
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        INSERT INTO [dbo].[UserActivities] (
            [UserId], [ActivityType], [ActionType], [FeatureActivitiesJson], [Timestamp]
        )
        VALUES (
            @ResolvedUser, 'ServiceRequestFile', 'Update', @FeatureJson, GETDATE()
        );

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        RAISERROR(@ErrorMessage, @ErrorSeverity, 1);
    END CATCH
END;
GO