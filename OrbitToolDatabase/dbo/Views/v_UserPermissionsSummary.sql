/*
    View: v_UserPermissionsSummary
    Description: Summary of permissions per user across all service applications.
*/
CREATE VIEW [dbo].[v_UserPermissionsSummary]
AS
SELECT 
    u.[UserId],
    u.[FullName] AS UserFullName,
    u.[Email] AS UserEmail,
    u.[Department] AS UserDepartment,
    COUNT(DISTINCT sap.[ServiceApplicationId]) AS TotalServiceAccess,
    COUNT(DISTINCT sap.[ResourcePermissionId]) AS TotalPermissionTypes,
    COUNT(DISTINCT CASE WHEN sap.[IsGranted] = 1 THEN sap.[ServiceApplicationId] END) AS GrantedServiceAccess,
    COUNT(DISTINCT CASE WHEN sap.[IsGranted] = 0 THEN sap.[ServiceApplicationId] END) AS DeniedServiceAccess,
    (
        SELECT STRING_AGG(rp.[PermissionKey], ', ') 
        FROM (
            SELECT DISTINCT rp.[PermissionKey]
            FROM [dbo].[ServiceAppPermissions] sap2
            INNER JOIN [dbo].[ResourcePermissions] rp ON sap2.[ResourcePermissionId] = rp.[Id]
            WHERE sap2.[UserId] = u.[UserId]
              AND sap2.[IsGranted] = 1
        ) AS distinct_permissions
    ) AS GrantedPermissions,
    (
        SELECT STRING_AGG(sa.[Name], ', ')
        FROM (
            SELECT DISTINCT sa.[Name]
            FROM [dbo].[ServiceAppPermissions] sap2
            INNER JOIN [dbo].[ServiceApplications] sa ON sap2.[ServiceApplicationId] = sa.[Id]
            WHERE sap2.[UserId] = u.[UserId]
              AND sap2.[IsGranted] = 1
              AND sa.[IsActive] = 1
        ) AS distinct_services
    ) AS AccessibleServices,
    MAX(sap.[LastUpdatedAt]) AS LastPermissionUpdate,
    MAX(sap.[LastUpdatedBy]) AS LastPermissionUpdater
FROM [dbo].[Users] u
LEFT JOIN [dbo].[ServiceAppPermissions] sap ON u.[UserId] = sap.[UserId]
GROUP BY u.[UserId], u.[FullName], u.[Email], u.[Department];
GO