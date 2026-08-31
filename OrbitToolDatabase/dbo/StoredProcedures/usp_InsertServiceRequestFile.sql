/*
    Stored Procedure: usp_InsertServiceRequestFile
    Description: Inserts a new service request file with support for delta chains.
    Handles both base snapshots and delta patches.
*/
CREATE PROCEDURE [dbo].[usp_InsertServiceRequestFile]
    @ServiceOperationId INT,
    @Name NVARCHAR(250),
    @FileFormat VARCHAR(10) = NULL,
    @IsBaseSnapshot BIT = 1,
    @ParentBaseId INT = NULL,
    @ParentDeltaId INT = NULL,
    @CompressedData VARBINARY(MAX),
    @UncompressedSizeBytes INT = NULL,
    @CompressionAlgorithmType VARCHAR(50) = NULL,
    @ContentHash VARCHAR(64) = NULL,
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
        DECLARE @NewId INT;
        DECLARE @ActivityId BIGINT;
        DECLARE @Notes NVARCHAR(MAX);
        DECLARE @CalculatedHash VARCHAR(64);
        DECLARE @DeltaDepth INT = 0;
        DECLARE @OperationName NVARCHAR(200);
        DECLARE @ServiceName NVARCHAR(200);
        DECLARE @ServiceAppPublicId UNIQUEIDENTIFIER;

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Get operation and service details
        SELECT 
            @OperationName = so.[OperationName],
            @ServiceName = sa.[Name],
            @ServiceAppPublicId = sa.[PublicId]
        FROM [dbo].[ServiceOperations] so
        INNER JOIN [dbo].[ServiceApplications] sa ON so.[ServiceApplicationId] = sa.[Id]
        WHERE so.[Id] = @ServiceOperationId;

        IF @OperationName IS NULL
        BEGIN
            RAISERROR('Operation with Id %d not found.', 16, 1, @ServiceOperationId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Calculate hash if not provided
        IF @ContentHash IS NULL AND @CompressedData IS NOT NULL
        BEGIN
            SET @CalculatedHash = CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', @CompressedData), 2);
        END
        ELSE
        BEGIN
            SET @CalculatedHash = @ContentHash;
        END

        -- Calculate delta depth
        IF @IsBaseSnapshot = 0
        BEGIN
            -- If this is a delta, get the depth from the parent delta
            IF @ParentDeltaId IS NOT NULL
            BEGIN
                SELECT @DeltaDepth = [DeltaDepth] + 1
                FROM [dbo].[ServiceRequestFiles]
                WHERE [Id] = @ParentDeltaId
                  AND [IsActive] = 1;
            END
            ELSE IF @ParentBaseId IS NOT NULL
            BEGIN
                -- If directly referencing base, depth is 1
                SET @DeltaDepth = 1;
            END
        END

        -- Validate parent references
        IF @IsBaseSnapshot = 0
        BEGIN
            IF @ParentBaseId IS NULL AND @ParentDeltaId IS NULL
            BEGIN
                RAISERROR('Delta files must reference either a ParentBaseId or ParentDeltaId.', 16, 1);
                IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                    ROLLBACK TRANSACTION;
                RETURN;
            END

            -- Validate parent exists
            IF @ParentBaseId IS NOT NULL
            BEGIN
                IF NOT EXISTS (
                    SELECT 1 
                    FROM [dbo].[ServiceRequestFiles] 
                    WHERE [Id] = @ParentBaseId 
                      AND [IsBaseSnapshot] = 1 
                      AND [IsActive] = 1
                )
                BEGIN
                    RAISERROR('Parent base file with Id %d not found or inactive.', 16, 1, @ParentBaseId);
                    IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                        ROLLBACK TRANSACTION;
                    RETURN;
                END
            END

            IF @ParentDeltaId IS NOT NULL
            BEGIN
                IF NOT EXISTS (
                    SELECT 1 
                    FROM [dbo].[ServiceRequestFiles] 
                    WHERE [Id] = @ParentDeltaId 
                      AND [IsBaseSnapshot] = 0 
                      AND [IsActive] = 1
                )
                BEGIN
                    RAISERROR('Parent delta file with Id %d not found or inactive.', 16, 1, @ParentDeltaId);
                    IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                        ROLLBACK TRANSACTION;
                    RETURN;
                END
            END
        END

        -- Calculate record version
        SET @NewRecordVersion = [dbo].[fn_CalculateVersion](NULL);

        -- Insert new record
        INSERT INTO [dbo].[ServiceRequestFiles] (
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
        )
        VALUES (
            @ServiceOperationId,
            @FileFormat,
            @Name,
            @IsBaseSnapshot,
            @ParentBaseId,
            @ParentDeltaId,
            @DeltaDepth,
            @CompressedData,
            @UncompressedSizeBytes,
            @CompressionAlgorithmType,
            @CalculatedHash,
            @NewRecordVersion,
            1,  -- Active
            GETDATE(),
            @ResolvedUser,
            NULL,  -- No updates yet
            NULL   -- No updates yet
        );

        SET @NewId = SCOPE_IDENTITY();

        -- Build notes
        SET @Notes = CONCAT('Service request file created: ', @Name, 
                           ' (Operation: ', @OperationName, 
                           ', Service: ', @ServiceName, 
                           ', Type: ', CASE WHEN @IsBaseSnapshot = 1 THEN 'Base' ELSE 'Delta' END, ')');

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Create' AS ChangeType,
                @ServiceOperationId AS OperationId,
                @OperationName AS OperationName,
                @ServiceAppPublicId AS ServiceId,
                @ServiceName AS ServiceName,
                @Name AS FileName,
                @FileFormat AS FileFormat,
                @IsBaseSnapshot AS IsBaseSnapshot,
                @DeltaDepth AS DeltaDepth,
                @ParentBaseId AS ParentBaseId,
                @ParentDeltaId AS ParentDeltaId,
                @UncompressedSizeBytes AS SizeBytes,
                @CompressionAlgorithmType AS CompressionAlgorithm,
                @CalculatedHash AS ContentHash,
                @NewRecordVersion AS RecordVersion
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'ServiceRequestFileCreate',
            @ActionType = 'Create',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'ServiceApplication',
            @RelatedEntityId = @ServiceAppPublicId,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the new record
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
        WHERE [Id] = @NewId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error creating service request file: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO