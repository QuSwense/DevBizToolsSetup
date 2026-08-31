/*
    View: v_RolePermissionSummary
    Description: Summary of permissions per role.
*/
CREATE VIEW [dbo].[v_RolePermissionSummary]
AS
SELECT 
    rp.[Role],
    
    -- Permission counts
    COUNT(DISTINCT rp.[Id]) AS TotalPermissions,
    COUNT(DISTINCT CASE WHEN rp.[IsGranted] = 1 THEN rp.[Id] END) AS GrantedPermissions,
    COUNT(DISTINCT CASE WHEN rp.[IsGranted] = 0 THEN rp.[Id] END) AS DeniedPermissions,
    COUNT(DISTINCT CASE WHEN rp.[IsActive] = 1 THEN rp.[Id] END) AS ActivePermissions,
    COUNT(DISTINCT CASE WHEN rp.[IsActive] = 0 THEN rp.[Id] END) AS InactivePermissions,
    
    -- Permission categories
    COUNT(DISTINCT 
        LEFT(res.[PermissionKey], CHARINDEX(':', res.[PermissionKey] + ':') - 1)
    ) AS UniquePermissionCategories,
    
    -- Permission list
    STUFF((
        SELECT DISTINCT ', ' + res2.[PermissionKey]
        FROM [dbo].[RolePermissions] rp2
        INNER JOIN [dbo].[ResourcePermissions] res2 ON rp2.[ResourcePermissionId] = res2.[Id]
        WHERE rp2.[Role] = rp.[Role]
          AND rp2.[IsGranted] = 1
          AND rp2.[IsActive] = 1
        FOR XML PATH('')
    ), 1, 2, '') AS GrantedPermissionKeys,
    
    -- Last permission activity
    MAX(rp.[CreatedAt]) AS LastPermissionGranted,
    MAX(rp.[LastUpdatedAt]) AS LastPermissionUpdated

FROM [dbo].[RolePermissions] rp
INNER JOIN [dbo].[ResourcePermissions] res ON rp.[ResourcePermissionId] = res.[Id]
GROUP BY rp.[Role];
GO