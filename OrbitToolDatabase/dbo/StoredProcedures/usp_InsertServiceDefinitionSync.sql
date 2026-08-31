/*
    Stored Procedure: usp_InsertServiceDefinitionSync
    Description: Inserts a new service definition sync record with audit logging.
    This is used when syncing a definition file for the first time or when the definition has changed.
    
    Logic:
    - Creates a new sync record with the definition content
    - Calculates file hash and compression details
    - Handles nested transactions gracefully
    - Logs the activity to UserActivities table
*/
CREATE PROCEDURE [dbo].[usp_InsertServiceDefinitionSync]
    @ServiceApplicationPublicId UNIQUEIDENTIFIER,
    @CompressedContent VARBINARY(MAX),
    @UncompressedSizeBytes INT = NULL,
    @CompressionAlgorithmType VARCHAR(50) = NULL,
    @UserId NVARCHAR(20) = NULL,
    @ContentHash VARCHAR(64) = NULL  -- Optional: if not provided, will be calculated
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
        DECLARE @ServiceAppId INT;
        DECLARE @ServiceAppName NVARCHAR(200);
        DECLARE @BaseUrl NVARCHAR(500);
        DECLARE @DefinitionRelativeUrl NVARCHAR(250);
        DECLARE @DefinitionUrl NVARCHAR(500);
        DECLARE @NewRecordVersion VARCHAR(50);
        DECLARE @NewId INT;
        DECLARE @ActivityId BIGINT;
        DECLARE @Notes NVARCHAR(MAX);
        DECLARE @CalculatedContentHash VARCHAR(64);
        DECLARE @ExistingSyncId INT;
        DECLARE @ExistingRecordVersion VARCHAR(50);

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Get the service application details
        SELECT TOP 1
            @ServiceAppId = [Id],
            @ServiceAppName = [Name],
            @BaseUrl = [BaseUrl],
            @DefinitionRelativeUrl = [DefinitionRelativeUrl]
        FROM [dbo].[ServiceApplications]
        WHERE [PublicId] = @ServiceApplicationPublicId
          AND [IsActive] = 1
        ORDER BY [Id] DESC;

        IF @ServiceAppId IS NULL
        BEGIN
            RAISERROR('Service application not found or inactive.', 16, 1);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Check if DefinitionRelativeUrl is configured
        IF @DefinitionRelativeUrl IS NULL
        BEGIN
            RAISERROR('Service application does not have a definition URL configured.', 16, 1);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Build the full Definition URL
        SET @DefinitionUrl = @BaseUrl + @DefinitionRelativeUrl;

        -- Calculate file hash if not provided
        IF @ContentHash IS NULL AND @CompressedContent IS NOT NULL
        BEGIN
            -- Use SQL Server's HASHBYTES function to calculate SHA256
            -- Note: This requires SQL Server 2012+ for SHA2_256
            SET @CalculatedContentHash = CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', @CompressedContent), 2);
        END
        ELSE
        BEGIN
            SET @CalculatedContentHash = @ContentHash;
        END

        -- Check if there's already a sync record for this service
        SELECT TOP 1
            @ExistingSyncId = [Id],
            @ExistingRecordVersion = [RecordVersion]
        FROM [dbo].[ServiceDefinitionSyncs]
        WHERE [ServiceApplicationId] = @ServiceAppId
        ORDER BY [Id] DESC;

        -- If there's an existing record and the content hasn't changed, just return it
        IF @ExistingSyncId IS NOT NULL AND @CalculatedContentHash IS NOT NULL
        BEGIN
            DECLARE @ExistingHash VARCHAR(64);
            
            SELECT @ExistingHash = [ContentHash]
            FROM [dbo].[ServiceDefinitionSyncs]
            WHERE [Id] = @ExistingSyncId;

            IF @ExistingHash = @CalculatedContentHash
            BEGIN
                -- Content hasn't changed, just return the existing record
                IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                    COMMIT TRANSACTION;

                SELECT 
                    [Id],
                    [ServiceApplicationId],
                    [DefinitionUrl],
                    [CompressedContent],
                    [UncompressedSizeBytes],
                    [CompressionAlgorithmType],
                    [ContentHash],
                    [RecordVersion],
                    [CreatedAt],
                    [CreatedBy],
                    [LastUpdatedAt],
                    [LastUpdatedBy]
                FROM [dbo].[ServiceDefinitionSyncs]
                WHERE [Id] = @ExistingSyncId;
                
                RETURN;
            END
        END

        -- Calculate new record version
        SET @NewRecordVersion = [dbo].[fn_CalculateVersion](@ExistingRecordVersion);

        -- Insert new sync record
        INSERT INTO [dbo].[ServiceDefinitionSyncs] (
            [ServiceApplicationId],
            [DefinitionUrl],
            [CompressedContent],
            [UncompressedSizeBytes],
            [CompressionAlgorithmType],
            [ContentHash],
            [RecordVersion],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy]
        )
        VALUES (
            @ServiceAppId,
            @DefinitionUrl,
            @CompressedContent,
            @UncompressedSizeBytes,
            @CompressionAlgorithmType,
            @CalculatedContentHash,
            @NewRecordVersion,
            GETDATE(),
            @ResolvedUser,
            NULL,  -- No updates yet
            NULL   -- No updates yet
        );

        SET @NewId = SCOPE_IDENTITY();

        -- Build notes string
        SET @Notes = CONCAT('Definition synced for service: ', @ServiceAppName, 
                           ' (Size: ', @UncompressedSizeBytes, ' bytes, Hash: ', @CalculatedContentHash, ')');

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'DefinitionSync' AS ChangeType,
                @ServiceApplicationPublicId AS ServiceId,
                @ServiceAppName AS ServiceName,
                @DefinitionUrl AS DefinitionUrl,
                @UncompressedSizeBytes AS SizeBytes,
                @CompressionAlgorithmType AS CompressionAlgorithm,
                @CalculatedContentHash AS ContentHash,
                @NewRecordVersion AS RecordVersion
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'ServiceDefinitionSync',
            @ActionType = 'Sync',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'ServiceApplication',
            @RelatedEntityId = @ServiceApplicationPublicId,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the new record
        SELECT 
            [Id],
            [ServiceApplicationId],
            [DefinitionUrl],
            [CompressedContent],
            [UncompressedSizeBytes],
            [CompressionAlgorithmType],
            [ContentHash],
            [RecordVersion],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy],
            @ActivityId AS AuditActivityId
        FROM [dbo].[ServiceDefinitionSyncs]
        WHERE [Id] = @NewId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error syncing service definition: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO