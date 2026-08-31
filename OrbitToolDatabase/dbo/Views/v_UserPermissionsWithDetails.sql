/*
    View: v_UserPermissionsWithDetails
    Description: Comprehensive view of user permissions with user and resource details.
*/
CREATE VIEW [dbo].[v_UserPermissionsWithDetails]
AS
SELECT 
    up.[Id] AS UserPermissionId,
    up.[PublicId],
    up.[UserId],
    up.[ResourcePermissionId],
    up.[IsGranted],
    up.[IsActive],
    up.[CreatedAt] AS PermissionCreatedAt,
    up.[CreatedBy] AS PermissionCreatedBy,
    up.[LastUpdatedAt] AS PermissionLastUpdatedAt,
    up.[LastUpdatedBy] AS PermissionLastUpdatedBy,
    
    -- User details
    CONCAT(u.[FirstName], ' ', u.[LastName]) AS UserFullName,
    u.[Email] AS UserEmail,
    u.[Department] AS UserDepartment,
    
    -- Permission details
    rp.[PermissionKey],
    rp.[Id] AS ResourcePermissionKeyId,
    rp.[PublicId] AS ResourcePermissionPublicId,
    
    -- Derived fields
    CASE 
        WHEN up.[IsGranted] = 1 THEN 'Granted'
        ELSE 'Denied'
    END AS PermissionStatus,
    CASE 
        WHEN up.[IsActive] = 1 THEN 'Active'
        ELSE 'Inactive'
    END AS StatusDescription,
    
    -- Permission category (assuming format like "soapapplication:read")
    LEFT(rp.[PermissionKey], CHARINDEX(':', rp.[PermissionKey] + ':') - 1) AS PermissionCategory,
    RIGHT(rp.[PermissionKey], LEN(rp.[PermissionKey]) - CHARINDEX(':', rp.[PermissionKey] + ':')) AS PermissionAction,
    
    -- Age
    DATEDIFF(DAY, up.[CreatedAt], GETDATE()) AS AgeDays

FROM [dbo].[UserPermissions] up
INNER JOIN [dbo].[Users] u ON up.[UserId] = u.[UserId]
INNER JOIN [dbo].[ResourcePermissions] rp ON up.[ResourcePermissionId] = rp.[Id];
GO