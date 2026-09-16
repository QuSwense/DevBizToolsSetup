-- =============================================
-- Author:      OrbitHub
-- Create date: 2026-09-06
-- Description: Updates an existing UI action (keyed on PublicId)
-- =============================================
CREATE PROCEDURE [dbo].[usp_UpdateUIActions]
    @PublicId              UNIQUEIDENTIFIER,
    @ActionName            NVARCHAR(50) = NULL,
    @DisplayName           NVARCHAR(100) = NULL,
    @ResourcePermissionId BIGINT = NULL,
    @ActionType            NVARCHAR(20) = NULL,
    @UiElementId           NVARCHAR(100) = NULL,
    @IsActive              BIT = NULL,
    @UserId                NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ResolvedUserId  NVARCHAR(20) = COALESCE(@UserId, SYSTEM_USER, 'SYSTEM');
    DECLARE @LocalTranStarted BIT = 0;
    DECLARE @ActivityId      BIGINT;
    DECLARE @ActionId        INT;
    DECLARE @CurrentPageId   INT;
    DECLARE @CurrentActionName NVARCHAR(50);

    -- Look up the action by PublicId with lock hints
    SELECT @ActionId = [Id], @CurrentPageId = [PageId], @CurrentActionName = [ActionName]
    FROM [dbo].[UIActions] WITH (UPDLOCK, HOLDLOCK)
    WHERE [PublicId] = @PublicId;

    IF @ActionId IS NULL
    BEGIN
        RAISERROR('UI action not found for the specified PublicId.', 16, 1);
        RETURN;
    END

    -- Validation: ActionName must not be empty if provided
    IF @ActionName IS NOT NULL AND LTRIM(RTRIM(@ActionName)) = N''
    BEGIN
        RAISERROR('Action name cannot be empty.', 16, 1);
        RETURN;
    END

    -- Validation: ActionName must be unique per page if changed
    IF @ActionName IS NOT NULL AND @ActionName <> @CurrentActionName
    BEGIN
        IF EXISTS (SELECT 1 FROM [dbo].[UIActions] WITH (UPDLOCK, HOLDLOCK) WHERE [PageId] = @CurrentPageId AND [ActionName] = @ActionName AND [Id] <> @ActionId)
        BEGIN
            RAISERROR('An action with the name ''%s'' already exists for this page.', 16, 1, @ActionName);
            RETURN;
        END
    END

    -- Validation: DisplayName must not be empty if provided
    IF @DisplayName IS NOT NULL AND LTRIM(RTRIM(@DisplayName)) = N''
    BEGIN
        RAISERROR('Display name cannot be empty.', 16, 1);
        RETURN;
    END

    -- Validation: ResourcePermissionId must exist if provided
    IF @ResourcePermissionId IS NOT NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM [dbo].[ResourcePermissions] WHERE [Id] = @ResourcePermissionId)
        BEGIN
            RAISERROR('Resource permission not found for the specified Id.', 16, 1);
            RETURN;
        END
    END

    -- Validation: ActionType must be valid if provided
    IF @ActionType IS NOT NULL AND @ActionType NOT IN ('Button', 'MenuItem', 'Tab', 'Link')
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

        UPDATE [dbo].[UIActions]
        SET
            [ActionName]            = ISNULL(@ActionName, [ActionName]),
            [DisplayName]           = ISNULL(@DisplayName, [DisplayName]),
            [ResourcePermissionId] = ISNULL(@ResourcePermissionId, [ResourcePermissionId]),
            [ActionType]            = ISNULL(@ActionType, [ActionType]),
            [UiElementId]           = ISNULL(@UiElementId, [UiElementId]),
            [IsActive]              = ISNULL(@IsActive, [IsActive]),
            [LastUpdatedAt]         = GETDATE(),
            [LastUpdatedBy]         = @ResolvedUserId
        WHERE [Id] = @ActionId;

        -- Audit logging
        EXEC [dbo].[usp_InsertUserActivities]
            @UserId            = @ResolvedUserId,
            @ActivityType      = 'UIActionUpdate',
            @ActionType        = 'Update',
            @RelatedEntityType = 'UIActions',
            @RelatedEntityId   = @PublicId,
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
            [ResourcePermissionId],
            [ActionType],
            [UiElementId],
            [IsActive],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy],
            @ActivityId AS [AuditActivityId]
        FROM [dbo].[UIActions]
        WHERE [Id] = @ActionId;
    END TRY
    BEGIN CATCH
        IF @LocalTranStarted = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO
