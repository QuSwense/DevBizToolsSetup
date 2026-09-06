-- Roles with permission and user counts
CREATE VIEW [dbo].[v_RolesWithDetails]
AS
SELECT
    ro.Id,
    ro.PublicId,
    ro.Name,
    ro.Description,
    ro.IsSystemRole,
    ro.IsActive,
    ro.CreatedAt,
    ro.CreatedBy,
    ro.LastUpdatedAt,
    ro.LastUpdatedBy,
    -- User and permission counts
    (SELECT COUNT(*) FROM [dbo].[Users] u WHERE u.RoleId = ro.Id) AS UserCount,
    (SELECT COUNT(*) FROM [dbo].[RolePermissions] rp WHERE rp.RoleId = ro.Id) AS PermissionCount,
    (SELECT COUNT(*) FROM [dbo].[RolePermissions] rp WHERE rp.RoleId = ro.Id AND rp.IsGranted = 1) AS GrantedPermissionCount,
    -- Role classification
    CASE WHEN ro.IsSystemRole = 1 THEN 'System' ELSE 'Custom' END AS RoleType,
    CASE WHEN ro.IsActive = 1 THEN 'Active' ELSE 'Inactive' END AS StatusDescription,
    -- Age in days since creation
    DATEDIFF(DAY, ro.CreatedAt, GETDATE()) AS AgeDays
FROM [dbo].[Roles] ro;
GO
