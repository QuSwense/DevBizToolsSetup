-- =============================================
-- Author:      OrbitHub
-- Create date: 2026-09-06
-- Description: Creates a new global setting
-- =============================================
CREATE PROCEDURE [dbo].[usp_CreateGlobalSetting]
    @Category NVARCHAR(50) = 'General',
    @SettingKey NVARCHAR(100),
    @SettingValue NVARCHAR(MAX),
    @DataType VARCHAR(20) = 'String',
    @Description NVARCHAR(500) = NULL,
    @IsUserOverridable BIT = 0,
    @IsActive BIT = 1,
    @UserId NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LocalTranStarted BIT = 0;
    DECLARE @ActivityId BIGINT;
    DECLARE @NewPublicId UNIQUEIDENTIFIER;
    DECLARE @ResolvedUserId NVARCHAR(20);

    BEGIN TRY
        -- Resolve user context
        SET @ResolvedUserId = COALESCE(@UserId, SYSTEM_USER, 'SYSTEM');

        -- Validation: SettingKey not empty
        IF @SettingKey IS NULL OR LTRIM(RTRIM(@SettingKey)) = ''
        BEGIN
            RAISERROR('SettingKey cannot be empty.', 16, 1);
            RETURN;
        END

        -- Validation: SettingKey unique
        IF EXISTS (SELECT 1 FROM [dbo].[GlobalSettings] WHERE [SettingKey] = @SettingKey)
        BEGIN
            RAISERROR('SettingKey already exists. Must be unique.', 16, 1);
            RETURN;
        END

        -- Validation: DataType in allowed list
        IF @DataType NOT IN ('String', 'Integer', 'Decimal', 'Boolean', 'Json', 'Xml', 'DateTime')
        BEGIN
            RAISERROR('Invalid DataType. Must be one of: String, Integer, Decimal, Boolean, Json, Xml, DateTime.', 16, 1);
            RETURN;
        END

        -- Start transaction if not already in one
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @LocalTranStarted = 1;
        END

        -- Generate new PublicId
        SET @NewPublicId = NEWID();

        -- Insert the global setting
        INSERT INTO [dbo].[GlobalSettings] (
            [PublicId],
            [Category],
            [SettingKey],
            [SettingValue],
            [DataType],
            [Description],
            [IsUserOverridable],
            [IsActive],
            [CreatedBy]
        )
        VALUES (
            @NewPublicId,
            @Category,
            @SettingKey,
            @SettingValue,
            @DataType,
            @Description,
            @IsUserOverridable,
            @IsActive,
            @ResolvedUserId
        );

        -- Audit logging
        EXEC [dbo].[usp_InsertUserActivity]
            @UserId = @ResolvedUserId,
            @ActivityType = 'GlobalSettingCreate',
            @ActionType = 'Create',
            @RelatedEntityType = 'GlobalSettings',
            @RelatedEntityId = @NewPublicId,
            @ActivityId = @ActivityId OUTPUT;

        -- Commit if we started the transaction
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            COMMIT TRANSACTION;

        -- Return result set
        SELECT
            [Id],
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
        WHERE [PublicId] = @NewPublicId;

    END TRY
    BEGIN CATCH
        -- Rollback if we started the transaction
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Re-throw error
        THROW;
    END CATCH
END
