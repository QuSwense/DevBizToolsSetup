-- UI pages with parent/child info and action counts
CREATE VIEW [dbo].[v_UIPagesWithDetails]
AS
SELECT
    up.Id,
    up.PublicId,
    up.ParentId,
    up.Name,
    up.ResourcePermissionsId,
    up.FeatureFlag,
    up.IsActive,
    up.IsVisibleInNav,
    up.CreatedAt,
    up.CreatedBy,
    up.LastUpdatedAt,
    up.LastUpdatedBy,
    -- Parent page details
    parent.Name AS ParentPageName,
    parent.PublicId AS ParentPagePublicId,
    -- Required permission details
    rp.PermissionKey AS RequiredPermissionKey,
    rp.PublicId AS RequiredPermissionPublicId,
    -- Child and action counts
    (SELECT COUNT(*) FROM [dbo].[UIPages] child WHERE child.ParentId = up.Id) AS ChildPageCount,
    (SELECT COUNT(*) FROM [dbo].[UIActions] ua WHERE ua.PageId = up.Id) AS ActionCount,
    -- Hierarchy information
    CASE WHEN up.ParentId IS NULL THEN 0 ELSE 1 END AS HierarchyLevel,
    CASE WHEN up.ParentId IS NULL THEN up.Name ELSE parent.Name + ' > ' + up.Name END AS FullPath
FROM [dbo].[UIPages] up
LEFT JOIN [dbo].[UIPages] parent ON up.ParentId = parent.Id
INNER JOIN [dbo].[ResourcePermissions] rp ON up.ResourcePermissionsId = rp.Id;
GO
