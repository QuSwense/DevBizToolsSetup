/*
    View: v_RolePermissionsWithDetails
    Description: Comprehensive view of role permissions with resource details.
*/
CREATE VIEW [dbo].[v_RolePermissionsWithDetails]
AS
SELECT 
    rp.[Id] AS RolePermissionId,
    rp.[Role],
    rp.[ResourcePermissionId],
    rp.[IsGranted],
    rp.[IsActive],
    rp.[CreatedAt] AS PermissionCreatedAt,
    rp.[CreatedBy] AS PermissionCreatedBy,
    rp.[LastUpdatedAt] AS PermissionLastUpdatedAt,
    rp.[LastUpdatedBy] AS PermissionLastUpdatedBy,
    
    -- Permission details
    res.[PermissionKey],
    res.[Id] AS ResourcePermissionKeyId,
    res.[PublicId] AS ResourcePermissionPublicId,
    
    -- Derived fields
    CASE 
        WHEN rp.[IsGranted] = 1 THEN 'Granted'
        ELSE 'Denied'
    END AS PermissionStatus,
    CASE 
        WHEN rp.[IsActive] = 1 THEN 'Active'
        ELSE 'Inactive'
    END AS StatusDescription,
    
    -- Permission category
    LEFT(res.[PermissionKey], CHARINDEX(':', res.[PermissionKey] + ':') - 1) AS PermissionCategory,
    RIGHT(res.[PermissionKey], LEN(res.[PermissionKey]) - CHARINDEX(':', res.[PermissionKey] + ':')) AS PermissionAction,
    
    -- Age
    DATEDIFF(DAY, rp.[CreatedAt], GETDATE()) AS AgeDays

FROM [dbo].[RolePermissions] rp
INNER JOIN [dbo].[ResourcePermissions] res ON rp.[ResourcePermissionId] = res.[Id];
GO