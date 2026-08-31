/*
    View: v_UserPermissionsSummary
    Description: Summary of permissions per user across all service applications.
*/
CREATE VIEW [dbo].[v_UserPermissionsSummary]
AS
WITH GrantedPermissions AS (
    SELECT DISTINCT sap2.[UserId], rp.[PermissionKey]
    FROM [dbo].[ServiceAppPermissions] sap2
    INNER JOIN [dbo].[ResourcePermissions] rp ON sap2.[ResourcePermissionId] = rp.[Id]
    WHERE sap2.[IsGranted] = 1
),
AccessibleServices AS (
    SELECT DISTINCT sap2.[UserId], sa.[Name]
    FROM [dbo].[ServiceAppPermissions] sap2
    INNER JOIN [dbo].[ServiceApplications] sa ON sap2.[ServiceApplicationId] = sa.[Id]
    WHERE sap2.[IsGranted] = 1
      AND sa.[IsActive] = 1
)
SELECT 
    u.[UserId],
    CONCAT(u.[FirstName], ' ', u.[LastName]) AS UserFullName,
    u.[Email] AS UserEmail,
    u.[Department] AS UserDepartment,
    COUNT(DISTINCT sap.[ServiceApplicationId]) AS TotalServiceAccess,
    COUNT(DISTINCT sap.[ResourcePermissionId]) AS TotalPermissionTypes,
    COUNT(DISTINCT CASE WHEN sap.[IsGranted] = 1 THEN sap.[ServiceApplicationId] END) AS GrantedServiceAccess,
    COUNT(DISTINCT CASE WHEN sap.[IsGranted] = 0 THEN sap.[ServiceApplicationId] END) AS DeniedServiceAccess,
    (
        SELECT STRING_AGG(gp.[PermissionKey], ', ')
        FROM GrantedPermissions gp
        WHERE gp.[UserId] = u.[UserId]
    ) AS GrantedPermissions,
    (
        SELECT STRING_AGG(ass.[Name], ', ')
        FROM AccessibleServices ass
        WHERE ass.[UserId] = u.[UserId]
    ) AS AccessibleServices,
    MAX(sap.[LastUpdatedAt]) AS LastPermissionUpdate,
    MAX(sap.[LastUpdatedBy]) AS LastPermissionUpdater
FROM [dbo].[Users] u
LEFT JOIN [dbo].[ServiceAppPermissions] sap ON u.[UserId] = sap.[UserId]
GROUP BY u.[UserId], CONCAT(u.[FirstName], ' ', u.[LastName]), u.[Email], u.[Department];
GO