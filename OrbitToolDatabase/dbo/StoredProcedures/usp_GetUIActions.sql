-- =============================================
-- Author:      OrbitHub
-- Create date: 2026-09-06
-- Description: Gets all UI actions with optional filtering
-- =============================================
CREATE PROCEDURE [dbo].[usp_GetUIActions]
    @PagePublicId    UNIQUEIDENTIFIER = NULL,
    @IncludeInactive BIT = 0,
    @ActionType      NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PageId INT = NULL;

    -- Resolve PagePublicId to PageId if provided
    IF @PagePublicId IS NOT NULL
    BEGIN
        SELECT @PageId = [Id]
        FROM [dbo].[UIPages]
        WHERE [PublicId] = @PagePublicId;

        IF @PageId IS NULL
        BEGIN
            RAISERROR('UI page not found for the specified PublicId.', 16, 1);
            RETURN;
        END
    END

    SELECT
        a.[Id],
        a.[PublicId],
        a.[PageId],
        a.[ActionName],
        a.[DisplayName],
        a.[ResourcePermissionsId],
        a.[ActionType],
        a.[UiElementId],
        a.[IsActive],
        a.[CreatedAt],
        a.[CreatedBy],
        a.[LastUpdatedAt],
        a.[LastUpdatedBy],
        p.[Name] AS [PageName],
        rp.[PermissionKey] AS [PermissionKey]
    FROM [dbo].[UIActions] a
    INNER JOIN [dbo].[UIPages] p ON a.[PageId] = p.[Id]
    INNER JOIN [dbo].[ResourcePermissions] rp ON a.[ResourcePermissionsId] = rp.[Id]
    WHERE
        (@PagePublicId IS NULL OR a.[PageId] = @PageId)
        AND (@IncludeInactive = 1 OR a.[IsActive] = 1)
        AND (@ActionType IS NULL OR a.[ActionType] = @ActionType)
    ORDER BY p.[Name], a.[ActionName];
END
GO
