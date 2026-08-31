/*
    Stored Procedure: usp_UpdateServiceDefinitionSync
    Description: Updates an existing service definition sync record with audit logging.
    This is used when the definition content has changed or when updating metadata.
    
    Logic:
    - Updates the sync record with new content and metadata
    - Recalculates file hash if content changes
    - Handles nested transactions gracefully
    - Logs the activity to UserActivities table
*/
CREATE PROCEDURE [dbo].[usp_UpdateServiceDefinitionSync]
    @ServiceApplicationPublicId UNIQUEIDENTIFIER,
    @CompressedContent VARBINARY(MAX) = NULL,
    @UncompressedSizeBytes INT = NULL,
    @CompressionAlgorithmType VARCHAR(50) = NULL,
    @UserId NVARCHAR(20) = NULL,
    @ContentHash VARCHAR(64) = NULL
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
        DECLARE @ActivityId BIGINT;
        DECLARE @Notes NVARCHAR(MAX);
        DECLARE @CalculatedContentHash VARCHAR(64);
        DECLARE @ExistingSyncId INT;
        DECLARE @ExistingRecordVersion VARCHAR(50);
        DECLARE @ExistingContent VARBINARY(MAX);
        DECLARE @ExistingContentHash VARCHAR(64);
        DECLARE @ExistingDefinitionUrl NVARCHAR(500);
        DECLARE @ExistingUncompressedSizeBytes INT;
        DECLARE @ExistingCompressionAlgorithmType VARCHAR(50);
        DECLARE @ContentChanged BIT = 0;
        DECLARE @MetadataChanged BIT = 0;

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

        -- Build the full Definition URL
        SET @DefinitionUrl = @BaseUrl + @DefinitionRelativeUrl;

        -- Get the existing sync record
        SELECT TOP 1
            @ExistingSyncId = [Id],
            @ExistingRecordVersion = [RecordVersion],
            @ExistingContent = [CompressedContent],
            @ExistingContentHash = [ContentHash],
            @ExistingDefinitionUrl = [DefinitionUrl],
            @ExistingUncompressedSizeBytes = [UncompressedSizeBytes],
            @ExistingCompressionAlgorithmType = [CompressionAlgorithmType]
        FROM [dbo].[ServiceDefinitionSyncs]
        WHERE [ServiceApplicationId] = @ServiceAppId
        ORDER BY [Id] DESC;

        IF @ExistingSyncId IS NULL
        BEGIN
            RAISERROR('No sync record found for this service application.', 16, 1);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Calculate file hash if content is provided
        IF @CompressedContent IS NOT NULL
        BEGIN
            IF @ContentHash IS NULL
            BEGIN
                SET @CalculatedContentHash = CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', @CompressedContent), 2);
            END
            ELSE
            BEGIN
                SET @CalculatedContentHash = @ContentHash;
            END

            -- Check if content actually changed
            IF @ExistingContent != @CompressedContent
            BEGIN
                SET @ContentChanged = 1;
            END
        END
        ELSE
        BEGIN
            SET @CalculatedContentHash = @ExistingContentHash;
        END

        -- Check if metadata changed
        IF @UncompressedSizeBytes IS NOT NULL AND @UncompressedSizeBytes != @ExistingUncompressedSizeBytes
            SET @MetadataChanged = 1;

        IF @CompressionAlgorithmType IS NOT NULL AND @CompressionAlgorithmType != @ExistingCompressionAlgorithmType
            SET @MetadataChanged = 1;

        IF @DefinitionUrl != @ExistingDefinitionUrl
            SET @MetadataChanged = 1;

        -- If nothing changed, return the existing record
        IF @ContentChanged = 0 AND @MetadataChanged = 0
        BEGIN
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

        -- Calculate new record version
        SET @NewRecordVersion = [dbo].[fn_CalculateVersion](@ExistingRecordVersion);

        -- Update the sync record
        UPDATE [dbo].[ServiceDefinitionSyncs]
        SET
            [DefinitionUrl] = @DefinitionUrl,
            [CompressedContent] = ISNULL(@CompressedContent, [CompressedContent]),
            [UncompressedSizeBytes] = ISNULL(@UncompressedSizeBytes, [UncompressedSizeBytes]),
            [CompressionAlgorithmType] = ISNULL(@CompressionAlgorithmType, [CompressionAlgorithmType]),
            [ContentHash] = @CalculatedContentHash,
            [RecordVersion] = @NewRecordVersion,
            [LastUpdatedAt] = GETDATE(),
            [LastUpdatedBy] = @ResolvedUser
        WHERE [Id] = @ExistingSyncId;

        -- Build notes string
        SET @Notes = CONCAT('Definition updated for service: ', @ServiceAppName);
        IF @ContentChanged = 1
            SET @Notes = CONCAT(@Notes, ' (Content changed, Size: ', @UncompressedSizeBytes, ' bytes)');
        IF @MetadataChanged = 1
            SET @Notes = CONCAT(@Notes, ' (Metadata updated)');

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'DefinitionUpdate' AS ChangeType,
                @ServiceApplicationPublicId AS ServiceId,
                @ServiceAppName AS ServiceName,
                @DefinitionUrl AS DefinitionUrl,
                @UncompressedSizeBytes AS SizeBytes,
                @CompressionAlgorithmType AS CompressionAlgorithm,
                @CalculatedContentHash AS ContentHash,
                @NewRecordVersion AS NewRecordVersion,
                @ExistingRecordVersion AS OldRecordVersion,
                @ContentChanged AS ContentChanged,
                @MetadataChanged AS MetadataChanged
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'ServiceDefinitionUpdate',
            @ActionType = 'Update',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'ServiceApplication',
            @RelatedEntityId = @ServiceApplicationPublicId,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the updated record
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
        WHERE [Id] = @ExistingSyncId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        
        RAISERROR('Error updating service definition sync: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO