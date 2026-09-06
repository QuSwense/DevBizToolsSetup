-- =============================================
-- Author:      OrbitHub
-- Create date: 2026-09-06
-- Description: Creates a new UI action
-- =============================================
CREATE PROCEDURE [dbo].[usp_CreateUIAction]
    @PagePublicId          UNIQUEIDENTIFIER,
    @ActionName            NVARCHAR(50),
    @DisplayName           NVARCHAR(100),
    @ResourcePermissionsId BIGINT,
    @ActionType            NVARCHAR(20) = 'Button',
    @UiElementId           NVARCHAR(100) = NULL,
    @IsActive              BIT = 1,
    @UserId                NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ResolvedUserId  NVARCHAR(20) = COALESCE(@UserId, SYSTEM_USER, 'SYSTEM');
    DECLARE @LocalTranStarted BIT = 0;
    DECLARE @ActivityId      BIGINT;
    DECLARE @NewPublicId     UNIQUEIDENTIFIER = NEWID();
    DECLARE @PageId          INT;

    -- Validation: PagePublicId must exist
    SELECT @PageId = [Id]
    FROM [dbo].[UIPages]
    WHERE [PublicId] = @PagePublicId;

    IF @PageId IS NULL
    BEGIN
        RAISERROR('UI page not found for the specified PublicId.', 16, 1);
        RETURN;
    END

    -- Validation: ActionName must not be empty
    IF @ActionName IS NULL OR LTRIM(RTRIM(@ActionName)) = N''
    BEGIN
        RAISERROR('Action name cannot be empty.', 16, 1);
        RETURN;
    END

    -- Validation: ActionName must be unique per page
    IF EXISTS (SELECT 1 FROM [dbo].[UIActions] WHERE [PageId] = @PageId AND [ActionName] = @ActionName)
    BEGIN
        RAISERROR('An action with the name ''%s'' already exists for this page.', 16, 1, @ActionName);
        RETURN;
    END

    -- Validation: DisplayName must not be empty
    IF @DisplayName IS NULL OR LTRIM(RTRIM(@DisplayName)) = N''
    BEGIN
        RAISERROR('Display name cannot be empty.', 16, 1);
        RETURN;
    END

    -- Validation: ResourcePermissionsId must exist
    IF NOT EXISTS (SELECT 1 FROM [dbo].[ResourcePermissions] WHERE [Id] = @ResourcePermissionsId)
    BEGIN
        RAISERROR('Resource permission not found for the specified Id.', 16, 1);
        RETURN;
    END

    -- Validation: ActionType must be a valid value
    IF @ActionType NOT IN ('Button', 'MenuItem', 'Tab', 'Link')
    BEGIN
        RAISERROR('Action type must be one of: Button, MenuItem, Tab, Link.', 16, 1);
        RETURN;
    END

    BEGIN TRY
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @LocalTranStarted = 1;
        END

        INSERT INTO [dbo].[UIActions]
            ([PublicId], [PageId], [ActionName], [DisplayName], [ResourcePermissionsId],
             [ActionType], [UiElementId], [IsActive], [CreatedBy])
        VALUES
            (@NewPublicId, @PageId, @ActionName, @DisplayName, @ResourcePermissionsId,
             @ActionType, @UiElementId, @IsActive, @ResolvedUserId);

        -- Audit logging
        EXEC [dbo].[usp_InsertUserActivity]
            @UserId            = @ResolvedUserId,
            @ActivityType      = 'UIActionCreate',
            @ActionType        = 'Create',
            @RelatedEntityType = 'UIActions',
            @RelatedEntityId   = @NewPublicId,
            @ActivityId        = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1
            COMMIT TRANSACTION;

        -- Return result set
        SELECT
            [Id],
            [PublicId],
            [PageId],
            [ActionName],
            [DisplayName],
            [ResourcePermissionsId],
            [ActionType],
            [UiElementId],
            [IsActive],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy],
            @ActivityId AS [AuditActivityId]
        FROM [dbo].[UIActions]
        WHERE [PublicId] = @NewPublicId;
    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO
