/*
    View: v_UserPermissionSummary
    Description: Summary of permissions per user.
*/
CREATE VIEW [dbo].[v_UserPermissionSummary]
AS
SELECT 
    u.[UserId],
    CONCAT(u.[FirstName], ' ', u.[LastName]) AS UserFullName,
    u.[Email] AS UserEmail,
    u.[Department] AS UserDepartment,
    
    -- Permission counts
    COUNT(DISTINCT up.[Id]) AS TotalPermissions,
    COUNT(DISTINCT CASE WHEN up.[IsGranted] = 1 THEN up.[Id] END) AS GrantedPermissions,
    COUNT(DISTINCT CASE WHEN up.[IsGranted] = 0 THEN up.[Id] END) AS DeniedPermissions,
    COUNT(DISTINCT CASE WHEN up.[IsActive] = 1 THEN up.[Id] END) AS ActivePermissions,
    COUNT(DISTINCT CASE WHEN up.[IsActive] = 0 THEN up.[Id] END) AS InactivePermissions,
    
    -- Permission categories
    COUNT(DISTINCT 
        LEFT(rp.[PermissionKey], CHARINDEX(':', rp.[PermissionKey] + ':') - 1)
    ) AS UniquePermissionCategories,
    
    -- Permission list
    STUFF((
        SELECT DISTINCT ', ' + rp2.[PermissionKey]
        FROM [dbo].[UserPermissions] up2
        INNER JOIN [dbo].[ResourcePermissions] rp2 ON up2.[ResourcePermissionId] = rp2.[Id]
        WHERE up2.[UserId] = u.[UserId]
          AND up2.[IsGranted] = 1
          AND up2.[IsActive] = 1
        FOR XML PATH('')
    ), 1, 2, '') AS GrantedPermissionKeys,
    
    -- Last permission activity
    MAX(up.[CreatedAt]) AS LastPermissionGranted,
    MAX(up.[LastUpdatedAt]) AS LastPermissionUpdated

FROM [dbo].[Users] u
LEFT JOIN [dbo].[UserPermissions] up ON u.[UserId] = up.[UserId]
LEFT JOIN [dbo].[ResourcePermissions] rp ON up.[ResourcePermissionId] = rp.[Id]
GROUP BY u.[UserId], CONCAT(u.[FirstName], ' ', u.[LastName]), u.[Email], u.[Department];
GO