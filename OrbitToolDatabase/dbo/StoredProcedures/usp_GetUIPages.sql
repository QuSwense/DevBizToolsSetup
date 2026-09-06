-- =============================================
-- Author:      OrbitHub
-- Create date: 2026-09-06
-- Description: Gets all UI pages with optional filtering
-- =============================================
CREATE PROCEDURE [dbo].[usp_GetUIPages]
    @IncludeInactive BIT = 0,
    @ParentPublicId  UNIQUEIDENTIFIER = NULL,
    @Name            NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ParentId INT = NULL;

    -- Resolve ParentPublicId to ParentId if provided
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

    SELECT
        p.[Id],
        p.[PublicId],
        p.[ParentId],
        p.[Name],
        p.[ResourcePermissionsId],
        p.[FeatureFlag],
        p.[IsActive],
        p.[IsVisibleInNav],
        p.[CreatedAt],
        p.[CreatedBy],
        p.[LastUpdatedAt],
        p.[LastUpdatedBy],
        parent.[Name] AS [ParentPageName],
        (SELECT COUNT(*) FROM [dbo].[UIPages] child WHERE child.[ParentId] = p.[Id]) AS [ChildPageCount],
        (SELECT COUNT(*) FROM [dbo].[UIActions] a WHERE a.[PageId] = p.[Id]) AS [ActionCount]
    FROM [dbo].[UIPages] p
    LEFT JOIN [dbo].[UIPages] parent ON p.[ParentId] = parent.[Id]
    WHERE
        (@IncludeInactive = 1 OR p.[IsActive] = 1)
        AND (@ParentPublicId IS NULL OR p.[ParentId] = @ParentId)
        AND (@Name IS NULL OR p.[Name] = @Name)
    ORDER BY p.[Name];
END
GO
