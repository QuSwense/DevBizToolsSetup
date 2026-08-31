/*
    Stored Procedure: usp_GetRolePermissions
    Description: Gets all permissions for a specific role.
*/
CREATE PROCEDURE [dbo].[usp_GetRolePermissions]
    @Role NVARCHAR(50) = NULL,
    @IncludeInactive BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        rp.[Id] AS RolePermissionId,
        rp.[Role],
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
    INNER JOIN [dbo].[ResourcePermissions] res ON rp.[ResourcePermissionId] = res.[Id]
    WHERE (@Role IS NULL OR rp.[Role] = @Role)
      AND (@IncludeInactive = 1 OR rp.[IsActive] = 1)
    ORDER BY rp.[Role], res.[PermissionKey];
END;
GO