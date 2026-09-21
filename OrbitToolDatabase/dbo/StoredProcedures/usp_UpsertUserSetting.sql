/*
    Stored Procedure: usp_UpsertUserSetting

    Inserts or updates a user-specific configuration setting in UserSettings.

    Matching / Upsert Logic:
    - Searches for an existing record by:
        1. @UserSettingId (if provided)
        2. @PublicId (if provided and no match yet)
        3. @UserId + @GlobalSettingId composite key (if both provided and no match yet)
    - If a matching record is found:
        - Updates SettingValue, GlobalSettingId, and/or UserId (if non-null inputs passed).
        - Updates LastUpdatedAt timestamp to current date/time.
        - Sets WasCreated = 0 and SaveResult = 'Updated'.
    - If no matching record is found:
        - Validates that required fields (@UserId, @SettingValue) and FK references exist.
        - Inserts a new row into [dbo].[UserSettings].
        - Sets WasCreated = 1 and SaveResult = 'Created'.

    Returns the inserted or updated UserSettings row joined with GlobalSettings (SettingKey).
*/
CREATE OR ALTER PROCEDURE [dbo].[usp_UpsertUserSetting]
    @UserSettingId      INT = NULL,
    @PublicId           UNIQUEIDENTIFIER = NULL,
    @UserId             NVARCHAR(20) = NULL,
    @GlobalSettingId    INT = NULL,
    @SettingValue       NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @LocalTranStarted BIT = 0;

    IF @@TRANCOUNT = 0
    BEGIN
        BEGIN TRANSACTION;
        SET @LocalTranStarted = 1;
    END

    BEGIN TRY
        DECLARE
            @TargetId            INT = NULL,
            @TargetPublicId      UNIQUEIDENTIFIER = NULL,
            @TargetUserId        NVARCHAR(20) = NULL,
            @TargetGlobalId      INT = NULL,
            @ExistingValue       NVARCHAR(MAX) = NULL,
            @WasCreated          BIT = 0;

        /* ---------- 1. Resolve Target Record ---------- */
        -- Match by Primary Key Id
        IF @UserSettingId IS NOT NULL
        BEGIN
            SELECT TOP (1)
                @TargetId       = us.[Id],
                @TargetPublicId = us.[PublicId],
                @TargetUserId   = us.[UserId],
                @TargetGlobalId = us.[GlobalSettingId],
                @ExistingValue  = us.[SettingValue]
            FROM [dbo].[UserSettings] us WITH (UPDLOCK, HOLDLOCK)
            WHERE us.[Id] = @UserSettingId;
        END

        -- Match by PublicId (if not resolved by Id)
        IF @TargetId IS NULL AND @PublicId IS NOT NULL
        BEGIN
            SELECT TOP (1)
                @TargetId       = us.[Id],
                @TargetPublicId = us.[PublicId],
                @TargetUserId   = us.[UserId],
                @TargetGlobalId = us.[GlobalSettingId],
                @ExistingValue  = us.[SettingValue]
            FROM [dbo].[UserSettings] us WITH (UPDLOCK, HOLDLOCK)
            WHERE us.[PublicId] = @PublicId;
        END

        -- Match by Composite Key (UserId + GlobalSettingId)
        IF @TargetId IS NULL AND @UserId IS NOT NULL AND @GlobalSettingId IS NOT NULL
        BEGIN
            SELECT TOP (1)
                @TargetId       = us.[Id],
                @TargetPublicId = us.[PublicId],
                @TargetUserId   = us.[UserId],
                @TargetGlobalId = us.[GlobalSettingId],
                @ExistingValue  = us.[SettingValue]
            FROM [dbo].[UserSettings] us WITH (UPDLOCK, HOLDLOCK)
            WHERE us.[UserId] = @UserId AND us.[GlobalSettingId] = @GlobalSettingId;
        END

        /* ---------- 2. Update or Insert ---------- */
        IF @TargetId IS NOT NULL
        BEGIN
            /* UPDATE existing record */
            DECLARE @NewGlobalSettingId INT = ISNULL(@GlobalSettingId, @TargetGlobalId);
            DECLARE @NewUserId NVARCHAR(20) = ISNULL(@UserId, @TargetUserId);

            -- Validate FK GlobalSettingId if changed
            IF @GlobalSettingId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [dbo].[GlobalSettings] WHERE [Id] = @GlobalSettingId)
                RAISERROR('Global setting was not found.', 16, 1);

            -- Validate FK UserId if changed
            IF @UserId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [dbo].[Users] WHERE [UserId] = @UserId)
                RAISERROR('User was not found.', 16, 1);

            -- Validate uniqueness for (UserId, GlobalSettingId) if modified
            IF @NewGlobalSettingId IS NOT NULL AND EXISTS (
                SELECT 1
                FROM [dbo].[UserSettings] WITH (UPDLOCK, HOLDLOCK)
                WHERE [UserId] = @NewUserId
                  AND [GlobalSettingId] = @NewGlobalSettingId
                  AND [Id] <> @TargetId
            )
                RAISERROR('User setting for this user and global setting already exists.', 16, 1);

            UPDATE [dbo].[UserSettings]
            SET [GlobalSettingId] = @NewGlobalSettingId,
                [UserId]          = @NewUserId,
                [SettingValue]    = ISNULL(@SettingValue, [SettingValue]),
                [LastUpdatedAt]   = GETDATE()
            WHERE [Id] = @TargetId;

            SET @WasCreated = 0;
        END
        ELSE
        BEGIN
            /* INSERT new record */
            IF NULLIF(LTRIM(RTRIM(@UserId)), '') IS NULL
                RAISERROR('UserId is required for inserting a user setting.', 16, 1);

            IF @SettingValue IS NULL
                RAISERROR('SettingValue is required for inserting a user setting.', 16, 1);

            IF NOT EXISTS (SELECT 1 FROM [dbo].[Users] WHERE [UserId] = @UserId)
                RAISERROR('User was not found.', 16, 1);

            IF @GlobalSettingId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [dbo].[GlobalSettings] WHERE [Id] = @GlobalSettingId)
                RAISERROR('Global setting was not found.', 16, 1);

            -- Check if unique index already violated
            IF @GlobalSettingId IS NOT NULL AND EXISTS (
                SELECT 1
                FROM [dbo].[UserSettings] WITH (UPDLOCK, HOLDLOCK)
                WHERE [UserId] = @UserId AND [GlobalSettingId] = @GlobalSettingId
            )
                RAISERROR('User setting for this user and global setting already exists.', 16, 1);

            SET @TargetPublicId = COALESCE(@PublicId, NEWID());

            INSERT INTO [dbo].[UserSettings]
            (
                [PublicId],
                [GlobalSettingId],
                [UserId],
                [SettingValue],
                [LastUpdatedAt]
            )
            VALUES
            (
                @TargetPublicId,
                @GlobalSettingId,
                @UserId,
                @SettingValue,
                GETDATE()
            );

            SET @TargetId = CONVERT(INT, SCOPE_IDENTITY());
            SET @WasCreated = 1;
        END

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        /* ---------- 3. Return Result Set ---------- */
        SELECT
            us.[Id]                 AS UserSettingId,
            us.[PublicId],
            us.[GlobalSettingId],
            us.[UserId],
            us.[SettingValue],
            us.[LastUpdatedAt],
            gs.[SettingKey],
            @WasCreated             AS WasCreated,
            CASE WHEN @WasCreated = 1 THEN 'Created' ELSE 'Updated' END AS SaveResult
        FROM [dbo].[UserSettings] us
        LEFT JOIN [dbo].[GlobalSettings] gs ON us.[GlobalSettingId] = gs.[Id]
        WHERE us.[Id] = @TargetId;
    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        RAISERROR('%s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO

