-- =============================================
-- Author:      OrbitHub
-- Create date: 2026-09-06
-- Description: Creates a new UI page
-- =============================================
CREATE PROCEDURE [dbo].[usp_CreateUIPage]
    @ParentPublicId       UNIQUEIDENTIFIER = NULL,
    @Name                 NVARCHAR(100),
    @ResourcePermissionsId BIGINT,
    @FeatureFlag          NVARCHAR(100) = NULL,
    @IsActive             BIT = 1,
    @IsVisibleInNav       BIT = 1,
    @UserId               NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ResolvedUserId  NVARCHAR(20) = COALESCE(@UserId, SYSTEM_USER, 'SYSTEM');
    DECLARE @LocalTranStarted BIT = 0;
    DECLARE @ActivityId      BIGINT;
    DECLARE @NewPublicId     UNIQUEIDENTIFIER = NEWID();
    DECLARE @ParentId        INT = NULL;

    -- Validation: Name must not be empty
    IF @Name IS NULL OR LTRIM(RTRIM(@Name)) = N''
    BEGIN
        RAISERROR('Page name cannot be empty.', 16, 1);
        RETURN;
    END

    -- Validation: Name must be unique
    IF EXISTS (SELECT 1 FROM [dbo].[UIPages] WHERE [Name] = @Name)
    BEGIN
        RAISERROR('A page with the name ''%s'' already exists.', 16, 1, @Name);
        RETURN;
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
    END

    -- Validation: ResourcePermissionsId must exist
    IF NOT EXISTS (SELECT 1 FROM [dbo].[ResourcePermissions] WHERE [Id] = @ResourcePermissionsId)
    BEGIN
        RAISERROR('Resource permission not found for the specified Id.', 16, 1);
        RETURN;
    END

    BEGIN TRY
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @LocalTranStarted = 1;
        END

        INSERT INTO [dbo].[UIPages]
            ([PublicId], [ParentId], [Name], [ResourcePermissionsId], [FeatureFlag],
             [IsActive], [IsVisibleInNav], [CreatedBy])
        VALUES
            (@NewPublicId, @ParentId, @Name, @ResourcePermissionsId, @FeatureFlag,
             @IsActive, @IsVisibleInNav, @ResolvedUserId);

        -- Audit logging
        EXEC [dbo].[usp_InsertUserActivity]
            @UserId            = @ResolvedUserId,
            @ActivityType      = 'UIPageCreate',
            @ActionType        = 'Create',
            @RelatedEntityType = 'UIPages',
            @RelatedEntityId   = @NewPublicId,
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
