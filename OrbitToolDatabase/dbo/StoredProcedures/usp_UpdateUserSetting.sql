/*
    Stored Procedure: usp_UpdateUserSetting
    Description: Updates an existing user-specific setting with audit logging.
*/
CREATE PROCEDURE [dbo].[usp_UpdateUserSetting]
    @UserSettingId INT,
    @GlobalSettingId INT = NULL,
    @SettingValue NVARCHAR(MAX) = NULL,
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
        DECLARE @ActivityId BIGINT;
        DECLARE @Notes NVARCHAR(MAX);
        DECLARE @PublicId UNIQUEIDENTIFIER;
        DECLARE @TargetUserId NVARCHAR(20);
        DECLARE @ExistingGlobalSettingId INT;
        DECLARE @ExistingSettingValue NVARCHAR(MAX);
        DECLARE @SettingKey NVARCHAR(100);

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Get current details with lock
        SELECT TOP 1
            @PublicId = us.[PublicId],
            @TargetUserId = us.[UserId],
            @ExistingGlobalSettingId = us.[GlobalSettingId],
            @ExistingSettingValue = us.[SettingValue],
            @SettingKey = gs.[SettingKey]
        FROM [dbo].[UserSettings] us WITH (UPDLOCK, HOLDLOCK)
        LEFT JOIN [dbo].[GlobalSettings] gs ON us.[GlobalSettingId] = gs.[Id]
        WHERE us.[Id] = @UserSettingId;

        IF @TargetUserId IS NULL
        BEGIN
            RAISERROR('User setting with Id %d not found.', 16, 1, @UserSettingId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Check for duplicate user/global-setting pairing if the global setting link is changed
        IF @GlobalSettingId IS NOT NULL AND @GlobalSettingId <> @ExistingGlobalSettingId
        BEGIN
            IF EXISTS (
                SELECT 1
                FROM [dbo].[UserSettings]
                WHERE [UserId] = @TargetUserId
                  AND [GlobalSettingId] = @GlobalSettingId
                  AND [Id] != @UserSettingId
            )
            BEGIN
                RAISERROR('User setting for user "%s" and global setting %d already exists.', 16, 1, @TargetUserId, @GlobalSettingId);
                IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                    ROLLBACK TRANSACTION;
                RETURN;
            END

            -- Refresh setting key for the newly linked global setting
            SELECT @SettingKey = [SettingKey]
            FROM [dbo].[GlobalSettings]
            WHERE [Id] = @GlobalSettingId;
        END

        -- Update the record
        UPDATE [dbo].[UserSettings]
        SET
            [GlobalSettingId] = ISNULL(@GlobalSettingId, [GlobalSettingId]),
            [SettingValue] = ISNULL(@SettingValue, [SettingValue]),
            [LastUpdatedAt] = GETDATE()
        WHERE [Id] = @UserSettingId;

        -- Build notes
        SET @Notes = CONCAT('User setting updated for user: ', @TargetUserId,
                           ' (', ISNULL(@SettingKey, 'N/A'), ')');

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT
                'Update' AS ChangeType,
                @UserSettingId AS UserSettingId,
                @TargetUserId AS UserId,
                ISNULL(@GlobalSettingId, @ExistingGlobalSettingId) AS GlobalSettingId,
                @SettingKey AS SettingKey,
                @SettingValue AS SettingValue
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'UserSettingUpdate',
            @ActionType = 'Update',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'UserSettings',
            @RelatedEntityId = @PublicId,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the updated record
        SELECT
            [Id] AS UserSettingId,
            [PublicId],
            [GlobalSettingId],
            [UserId],
            [SettingValue],
            [LastUpdatedAt],
            @SettingKey AS SettingKey,
            @ActivityId AS AuditActivityId
        FROM [dbo].[UserSettings]
        WHERE [Id] = @UserSettingId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR('Error updating user setting: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO
