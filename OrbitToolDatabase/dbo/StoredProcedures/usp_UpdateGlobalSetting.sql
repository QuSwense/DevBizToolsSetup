/*
    Stored Procedure: usp_UpdateGlobalSetting
    Description: Updates an existing global setting with audit logging.
*/
CREATE PROCEDURE [dbo].[usp_UpdateGlobalSetting]
    @GlobalSettingId INT,
    @Category NVARCHAR(50) = NULL,
    @SettingKey NVARCHAR(100) = NULL,
    @SettingValue NVARCHAR(MAX) = NULL,
    @DataType VARCHAR(20) = NULL,
    @Description NVARCHAR(500) = NULL,
    @IsUserOverridable BIT = NULL,
    @IsActive BIT = NULL,
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
        DECLARE @ExistingCategory NVARCHAR(50);
        DECLARE @ExistingSettingKey NVARCHAR(100);
        DECLARE @ExistingSettingValue NVARCHAR(MAX);
        DECLARE @ExistingDataType VARCHAR(20);
        DECLARE @ExistingDescription NVARCHAR(500);
        DECLARE @ExistingIsUserOverridable BIT;
        DECLARE @ExistingIsActive BIT;

        -- Resolve audit user
        SET @ResolvedUser = COALESCE(
            @UserId,
            SYSTEM_USER,
            'SYSTEM'
        );

        -- Get current details with lock
        SELECT TOP 1
            @PublicId = [PublicId],
            @ExistingCategory = [Category],
            @ExistingSettingKey = [SettingKey],
            @ExistingSettingValue = [SettingValue],
            @ExistingDataType = [DataType],
            @ExistingDescription = [Description],
            @ExistingIsUserOverridable = [IsUserOverridable],
            @ExistingIsActive = [IsActive]
        FROM [dbo].[GlobalSettings] WITH (UPDLOCK, HOLDLOCK)
        WHERE [Id] = @GlobalSettingId;

        IF @ExistingSettingKey IS NULL
        BEGIN
            RAISERROR('Global setting with Id %d not found.', 16, 1, @GlobalSettingId);
            IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Check for duplicate setting key if changed
        IF @SettingKey IS NOT NULL AND @SettingKey <> @ExistingSettingKey
        BEGIN
            IF EXISTS (
                SELECT 1
                FROM [dbo].[GlobalSettings]
                WHERE [SettingKey] = @SettingKey
                  AND [Id] != @GlobalSettingId
            )
            BEGIN
                RAISERROR('Global setting with key "%s" already exists.', 16, 1, @SettingKey);
                IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
                    ROLLBACK TRANSACTION;
                RETURN;
            END
        END

        -- Update the record
        UPDATE [dbo].[GlobalSettings]
        SET
            [Category] = ISNULL(@Category, [Category]),
            [SettingKey] = ISNULL(@SettingKey, [SettingKey]),
            [SettingValue] = ISNULL(@SettingValue, [SettingValue]),
            [DataType] = ISNULL(@DataType, [DataType]),
            [Description] = ISNULL(@Description, [Description]),
            [IsUserOverridable] = ISNULL(@IsUserOverridable, [IsUserOverridable]),
            [IsActive] = ISNULL(@IsActive, [IsActive]),
            [LastUpdatedAt] = GETDATE(),
            [LastUpdatedBy] = @ResolvedUser
        WHERE [Id] = @GlobalSettingId;

        -- Build notes
        SET @Notes = CONCAT('Global setting updated: ', ISNULL(@SettingKey, @ExistingSettingKey));

        -- Audit log
        DECLARE @FeatureJson NVARCHAR(MAX) = (
            SELECT
                'Update' AS ChangeType,
                @GlobalSettingId AS GlobalSettingId,
                ISNULL(@SettingKey, @ExistingSettingKey) AS SettingKey,
                ISNULL(@Category, @ExistingCategory) AS Category,
                @SettingValue AS SettingValue,
                @DataType AS DataType,
                @Description AS Description,
                @IsUserOverridable AS IsUserOverridable,
                @IsActive AS IsActive
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );

        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUser,
            @ActivityType = 'GlobalSettingUpdate',
            @ActionType = 'Update',
            @FeatureActivitiesJson = @FeatureJson,
            @RelatedEntityType = 'GlobalSettings',
            @RelatedEntityId = @PublicId,
            @Notes = @Notes,
            @ActivityId = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return the updated record
        SELECT
            [Id] AS GlobalSettingId,
            [PublicId],
            [Category],
            [SettingKey],
            [SettingValue],
            [DataType],
            [Description],
            [IsUserOverridable],
            [IsActive],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy],
            @ActivityId AS AuditActivityId
        FROM [dbo].[GlobalSettings]
        WHERE [Id] = @GlobalSettingId;

    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR('Error updating global setting: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
    END CATCH
END;
GO
