/*
    View: v_ServiceAppPermissionsSummary
    Description: Summary of permissions per service application.
*/
CREATE VIEW [dbo].[v_ServiceAppPermissionsSummary]
AS
SELECT 
    sa.[PublicId] AS ServicePublicId,
    sa.[Id] AS ServiceInternalId,
    sa.[Name] AS ServiceName,
    sa.[ServiceType],
    sa.[BaseUrl],
    sa.[IsActive] AS ServiceIsActive,
    sa.[RecordVersion] AS ServiceVersion,
    COUNT(DISTINCT sap.[UserId]) AS TotalUsersWithAccess,
    COUNT(DISTINCT CASE WHEN sap.[IsGranted] = 1 THEN sap.[UserId] END) AS UsersWithGrantedAccess,
    COUNT(DISTINCT CASE WHEN sap.[IsGranted] = 0 THEN sap.[UserId] END) AS UsersWithDeniedAccess,
    COUNT(DISTINCT sap.[ResourcePermissionId]) AS TotalPermissionTypes,
    -- Use FOR XML PATH for compatibility with all SQL Server versions
    STUFF((
        SELECT DISTINCT ', ' + rp.[PermissionKey]
        FROM [dbo].[ServiceAppPermissions] sap2
        INNER JOIN [dbo].[ResourcePermissions] rp ON sap2.[ResourcePermissionId] = rp.[Id]
        WHERE sap2.[ServiceApplicationId] = sa.[Id]
          AND sap2.[IsGranted] = 1
        FOR XML PATH('')
    ), 1, 2, '') AS GrantedPermissions,
    STUFF((
        SELECT DISTINCT ', ' + CONCAT(u.[FirstName], ' ', u.[LastName])
        FROM [dbo].[ServiceAppPermissions] sap2
        INNER JOIN [dbo].[Users] u ON sap2.[UserId] = u.[UserId]
        WHERE sap2.[ServiceApplicationId] = sa.[Id]
          AND sap2.[IsGranted] = 1
        FOR XML PATH('')
    ), 1, 2, '') AS UsersWithAccess,
    MAX(sap.[LastUpdatedAt]) AS LastPermissionUpdate,
    MAX(sap.[LastUpdatedBy]) AS LastPermissionUpdater
FROM [dbo].[ServiceApplications] sa
LEFT JOIN [dbo].[ServiceAppPermissions] sap ON sa.[Id] = sap.[ServiceApplicationId]
GROUP BY sa.[PublicId], sa.[Id], sa.[Name], sa.[ServiceType], sa.[BaseUrl], sa.[IsActive], sa.[RecordVersion];
GO