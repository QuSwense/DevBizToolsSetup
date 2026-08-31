/*
    View: v_ServiceAppPermissionsWithDetails
    Description: Comprehensive view of all service application permissions with user and service details.
*/
CREATE VIEW [dbo].[v_ServiceAppPermissionsWithDetails]
AS
SELECT 
    sap.[Id] AS PermissionId,
    sap.[PublicId] AS PermissionPublicId,
    sap.[IsGranted],
    sap.[CreatedAt] AS PermissionCreatedAt,
    sap.[CreatedBy] AS PermissionCreatedBy,
    sap.[LastUpdatedAt] AS PermissionLastUpdatedAt,
    sap.[LastUpdatedBy] AS PermissionLastUpdatedBy,
    
    -- Service Details
    sa.[PublicId] AS ServicePublicId,
    sa.[Id] AS ServiceInternalId,
    sa.[Name] AS ServiceName,
    sa.[ServiceType],
    sa.[BaseUrl],
    sa.[RecordVersion] AS ServiceVersion,
    sa.[IsActive] AS ServiceIsActive,
    
    -- User Details
    u.[UserId],
    CONCAT(u.[FirstName], ' ', u.[LastName]) AS UserFullName,
    u.[Email] AS UserEmail,
    u.[Department] AS UserDepartment,
    
    -- Permission Details
    rp.[PermissionKey],
    rp.[Id] AS ResourcePermissionId,
    rp.[PublicId] AS ResourcePermissionPublicId,
    
    -- Derived fields
    CASE 
        WHEN sap.[IsGranted] = 1 THEN 'Granted'
        ELSE 'Denied'
    END AS PermissionStatus,
    
    -- Group by permission category (assuming format like "soapapplication:read")
    LEFT(rp.[PermissionKey], CHARINDEX(':', rp.[PermissionKey] + ':') - 1) AS PermissionCategory,
    RIGHT(rp.[PermissionKey], LEN(rp.[PermissionKey]) - CHARINDEX(':', rp.[PermissionKey] + ':')) AS PermissionAction,
    
    -- Permission description (for UI display)
    CONCAT(
        UPPER(LEFT(rp.[PermissionKey], 1)),
        LOWER(SUBSTRING(rp.[PermissionKey], 2, LEN(rp.[PermissionKey])))
    ) AS PermissionDisplayName

FROM [dbo].[ServiceAppPermissions] sap
INNER JOIN [dbo].[ServiceApplications] sa ON sap.[ServiceApplicationId] = sa.[Id]
INNER JOIN [dbo].[Users] u ON sap.[UserId] = u.[UserId]
INNER JOIN [dbo].[ResourcePermissions] rp ON sap.[ResourcePermissionId] = rp.[Id];
GO