-- Resource permissions with usage counts
CREATE VIEW [dbo].[v_ResourcePermissionsWithDetails]
AS
SELECT
    rp.Id,
    rp.PublicId,
    rp.PermissionKey,
    rp.CreatedAt,
    rp.CreatedBy,
    rp.LastUpdatedAt,
    rp.LastUpdatedBy,
    -- Permission key decomposition
    CASE
        WHEN CHARINDEX(':', rp.PermissionKey) > 0
        THEN LEFT(rp.PermissionKey, CHARINDEX(':', rp.PermissionKey) - 1)
        ELSE rp.PermissionKey
    END AS PermissionCategory,
    CASE
        WHEN CHARINDEX(':', rp.PermissionKey) > 0
        THEN RIGHT(rp.PermissionKey, LEN(rp.PermissionKey) - CHARINDEX(':', rp.PermissionKey))
        ELSE NULL
    END AS PermissionAction,
    -- Role and user assignment counts
    (SELECT COUNT(*) FROM [dbo].[RolePermissions] rpx WHERE rpx.ResourcePermissionId = rp.Id) AS RoleCount,
    (SELECT COUNT(*) FROM [dbo].[UserPermissions] upx WHERE upx.ResourcePermissionId = rp.Id) AS UserCount,
    (SELECT COUNT(*) FROM [dbo].[RolePermissions] rpx WHERE rpx.ResourcePermissionId = rp.Id AND rpx.IsGranted = 1) AS GrantedRoleCount,
    (SELECT COUNT(*) FROM [dbo].[UserPermissions] upx WHERE upx.ResourcePermissionId = rp.Id AND upx.IsGranted = 1) AS GrantedUserCount,
    -- Usage indicators
    CASE
        WHEN (SELECT COUNT(*) FROM [dbo].[RolePermissions] rpx WHERE rpx.ResourcePermissionId = rp.Id) > 0
          OR (SELECT COUNT(*) FROM [dbo].[UserPermissions] upx WHERE upx.ResourcePermissionId = rp.Id) > 0
        THEN 1 ELSE 0
    END AS IsInUse,
    CASE
        WHEN (SELECT COUNT(*) FROM [dbo].[RolePermissions] rpx WHERE rpx.ResourcePermissionId = rp.Id) > 0
          OR (SELECT COUNT(*) FROM [dbo].[UserPermissions] upx WHERE upx.ResourcePermissionId = rp.Id) > 0
        THEN 'In use'
        ELSE 'Not assigned'
    END AS UsageDescription,
    -- Age in days since creation
    DATEDIFF(DAY, rp.CreatedAt, GETDATE()) AS AgeDays
FROM [dbo].[ResourcePermissions] rp;
GO
