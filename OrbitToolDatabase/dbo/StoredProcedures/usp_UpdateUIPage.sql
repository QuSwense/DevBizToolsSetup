-- =============================================
-- Author:      OrbitHub
-- Create date: 2026-09-06
-- Description: Updates an existing UI page (keyed on PublicId)
-- =============================================
CREATE PROCEDURE [dbo].[usp_UpdateUIPage]
    @PublicId             UNIQUEIDENTIFIER,
    @ParentPublicId       UNIQUEIDENTIFIER = NULL,
    @Name                 NVARCHAR(100) = NULL,
    @ResourcePermissionsId BIGINT = NULL,
    @FeatureFlag          NVARCHAR(100) = NULL,
    @IsActive             BIT = NULL,
    @IsVisibleInNav       BIT = NULL,
    @UserId               NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ResolvedUserId  NVARCHAR(20) = COALESCE(@UserId, SYSTEM_USER, 'SYSTEM');
    DECLARE @LocalTranStarted BIT = 0;
    DECLARE @ActivityId      BIGINT;
    DECLARE @PageId          INT;
    DECLARE @ParentId        INT = NULL;
    DECLARE @CurrentName     NVARCHAR(100);

    -- Look up the page by PublicId with lock hints
    SELECT @PageId = [Id], @CurrentName = [Name]
    FROM [dbo].[UIPages] WITH (UPDLOCK, HOLDLOCK)
    WHERE [PublicId] = @PublicId;

    IF @PageId IS NULL
    BEGIN
        RAISERROR('UI page not found for the specified PublicId.', 16, 1);
        RETURN;
    END

    -- Validation: Name must not be empty if provided
    IF @Name IS NOT NULL AND LTRIM(RTRIM(@Name)) = N''
    BEGIN
        RAISERROR('Page name cannot be empty.', 16, 1);
        RETURN;
    END

    -- Validation: Name must be unique if changed
    IF @Name IS NOT NULL AND @Name <> @CurrentName
    BEGIN
        IF EXISTS (SELECT 1 FROM [dbo].[UIPages] WHERE [Name] = @Name AND [Id] <> @PageId)
        BEGIN
            RAISERROR('A page with the name ''%s'' already exists.', 16, 1, @Name);
            RETURN;
        END
    END

    -- Validation: ParentPublicId must exist if provided
    IF @ParentPublicId IS NOT NULL
    BEGIN
        SELECT @ParentId = [Id]
        FROM [dbo].[UIPages]
        WHERE [PublicId] = @ParentPublicId;

        IF @ParentId IS NULL
        BEGIN
            RAISERROR('Parent page not found for the specified PublicId.', 16, 1);
            RETURN;
        END

        -- Prevent circular reference: page cannot be its own parent
        IF @ParentId = @PageId
        BEGIN
            RAISERROR('A page cannot be its own parent.', 16, 1);
            RETURN;
        END

        -- Prevent circular reference: parent cannot be a descendant of this page
        -- Walk up the ancestor chain from the proposed parent; if we reach @PageId, it's circular
        DECLARE @CurrentAncestorId INT = @ParentId;
        DECLARE @Depth INT = 0;
        DECLARE @MaxDepth INT = 100; -- safety limit to prevent infinite loop on existing bad data

        WHILE @CurrentAncestorId IS NOT NULL AND @Depth < @MaxDepth
        BEGIN
            IF @CurrentAncestorId = @PageId
            BEGIN
                RAISERROR('Circular parent reference detected. The specified parent is a descendant of this page.', 16, 1);
                RETURN;
            END

            SELECT @CurrentAncestorId = [ParentId]
            FROM [dbo].[UIPages]
            WHERE [Id] = @CurrentAncestorId;

            SET @Depth = @Depth + 1;
        END
    END

    -- Validation: ResourcePermissionsId must exist if provided
    IF @ResourcePermissionsId IS NOT NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM [dbo].[ResourcePermissions] WHERE [Id] = @ResourcePermissionsId)
        BEGIN
            RAISERROR('Resource permission not found for the specified Id.', 16, 1);
            RETURN;
        END
    END

    BEGIN TRY
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @LocalTranStarted = 1;
        END

        UPDATE [dbo].[UIPages]
        SET
            [ParentId]             = ISNULL(@ParentId, [ParentId]),
            [Name]                 = ISNULL(@Name, [Name]),
            [ResourcePermissionsId] = ISNULL(@ResourcePermissionsId, [ResourcePermissionsId]),
            [FeatureFlag]          = ISNULL(@FeatureFlag, [FeatureFlag]),
            [IsActive]             = ISNULL(@IsActive, [IsActive]),
            [IsVisibleInNav]       = ISNULL(@IsVisibleInNav, [IsVisibleInNav]),
            [LastUpdatedAt]        = GETDATE(),
            [LastUpdatedBy]        = @ResolvedUserId
        WHERE [Id] = @PageId;

        -- Audit logging
        EXEC [dbo].[usp_InsertUserActivity]
            @UserId            = @ResolvedUserId,
            @ActivityType      = 'UIPageUpdate',
            @ActionType        = 'Update',
            @RelatedEntityType = 'UIPages',
            @RelatedEntityId   = @PublicId,
            @ActivityId        = @ActivityId OUTPUT;

        IF @LocalTranStarted = 1
            COMMIT TRANSACTION;

        -- Return result set
        SELECT
            [Id],
            [PublicId],
            [ParentId],
            [Name],
            [ResourcePermissionsId],
            [FeatureFlag],
            [IsActive],
            [IsVisibleInNav],
            [CreatedAt],
            [CreatedBy],
            [LastUpdatedAt],
            [LastUpdatedBy],
            @ActivityId AS [AuditActivityId]
        FROM [dbo].[UIPages]
        WHERE [Id] = @PageId;
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
