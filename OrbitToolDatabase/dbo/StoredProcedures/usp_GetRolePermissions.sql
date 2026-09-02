/*
    Stored Procedure: usp_GetRolePermissions
    Description: Gets all permissions for a specific role.
*/
CREATE PROCEDURE [dbo].[usp_GetRolePermissions]
    @RoleId INT = NULL,
    @IncludeInactive BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        rp.[Id] AS RolePermissionId,
        rp.[RoleId],
        ro.[Name] AS Role,
        rp.[ResourcePermissionId],
        rp.[IsGranted],
        rp.[IsActive],
        rp.[CreatedAt],
        rp.[CreatedBy],
        rp.[LastUpdatedAt],
        rp.[LastUpdatedBy],
        res.[PermissionKey],
        CASE 
            WHEN rp.[IsGranted] = 1 THEN 'Granted'
            ELSE 'Denied'
        END AS PermissionStatus,
        CASE 
            WHEN rp.[IsActive] = 1 THEN 'Active'
            ELSE 'Inactive'
        END AS StatusDescription
    FROM [dbo].[RolePermissions] rp
    INNER JOIN [dbo].[Roles] ro ON rp.[RoleId] = ro.[Id]
    INNER JOIN [dbo].[ResourcePermissions] res ON rp.[ResourcePermissionId] = res.[Id]
    WHERE (@RoleId IS NULL OR rp.[RoleId] = @RoleId)
      AND (@IncludeInactive = 1 OR rp.[IsActive] = 1)
    ORDER BY ro.[Name], res.[PermissionKey];
END;
GO