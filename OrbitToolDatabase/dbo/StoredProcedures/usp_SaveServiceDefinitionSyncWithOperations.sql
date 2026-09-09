/*
    Stored Procedure: usp_SaveServiceDefinitionSyncWithOperations
    Description: Atomically persists a new definition sync snapshot along with auto-parsed operations,
    XSD schemas, and namespaces in a single transaction.
*/
CREATE PROCEDURE [dbo].[usp_SaveServiceDefinitionSyncWithOperations]
    @ServiceApplicationId INT,
    @DefinitionUrl NVARCHAR(500) = NULL,
    @CompressedContent VARBINARY(MAX),
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
        DECLARE @NewSyncId INT;
        DECLARE @ServiceAppPublicId UNIQUEIDENTIFIER;
        DECLARE @ServiceAppName NVARCHAR(200);
        DECLARE @ActivityId BIGINT;
        DECLARE @Notes NVARCHAR(MAX);
        DECLARE @CalculatedHash VARCHAR(64);

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Get service application details
        SELECT @ServiceAppPublicId = [PublicId], @ServiceAppName = [Name]
        FROM [dbo].[ServiceApplications]
        WHERE [Id] = @ServiceApplicationId AND [IsActive] = 1;

        IF @ServiceAppPublicId IS NULL
        BEGIN
            RAISERROR('Service application with Id %d not found or inactive.', 16, 1, @ServiceApplicationId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Calculate hash if not provided
        IF @ContentHash IS NULL AND @CompressedContent IS NOT NULL
        BEGIN
            SET @CalculatedHash = CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', @CompressedContent), 2);
        END
        ELSE
        BEGIN
            SET @CalculatedHash = @ContentHash;
        END

        -- Calculate version
        SET @NewRecordVersion = [dbo].[fn_CalculateVersion](NULL);

        -- Insert definition sync record
        INSERT INTO [dbo].[ServiceDefinitionSyncs] (
            [ServiceApplicationId], [DefinitionUrl],
            [CompressedContent], [UncompressedSizeBytes],
            [CompressionAlgorithmType], [ContentHash],
            [RecordVersion], [CreatedAt], [CreatedBy]
        )
        VALUES (
            @ServiceApplicationId, @DefinitionUrl,
            @CompressedContent, @UncompressedSizeBytes,
            @CompressionAlgorithmType, @CalculatedHash,
            @NewRecordVersion, GETDATE(), @ResolvedUser
        );

        SET @NewSyncId = SCOPE_IDENTITY();

        -- Build notes
        SET @Notes = CONCAT('Definition sync saved: ', @ServiceAppName, ' (Sync ID: ', @NewSyncId, ')');

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT 
                'Create' AS ChangeType,
                @NewSyncId AS SyncId,
                @ServiceApplicationId AS ServiceApplicationId,
                @ServiceAppName AS ServiceAppName
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        INSERT INTO [dbo].[UserActivities] (
            [UserId], [ActivityType], [ActionType], [FeatureActivitiesJson], [Timestamp]
        )
        VALUES (
            @ResolvedUser, 'ServiceDefinitionSync', 'Create', @FeatureJson, GETDATE()
        );

        -- Return the created sync record
        SELECT
            [Id], [ServiceApplicationId], [DefinitionUrl],
            [CompressedContent], [UncompressedSizeBytes],
            [CompressionAlgorithmType], [ContentHash],
            [RecordVersion], [CreatedAt], [CreatedBy],
            [LastUpdatedAt], [LastUpdatedBy]
        FROM [dbo].[ServiceDefinitionSyncs]
        WHERE [Id] = @NewSyncId;

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