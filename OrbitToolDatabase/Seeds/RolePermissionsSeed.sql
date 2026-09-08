/*
    Seed RolePermissions - Grant permissions to system roles
*/
-- Get role IDs
DECLARE @DeveloperRoleId INT = (SELECT Id FROM [dbo].[Roles] WHERE Name = 'Developer')
DECLARE @AdminRoleId INT = (SELECT Id FROM [dbo].[Roles] WHERE Name = 'Admin')
DECLARE @ViewerRoleId INT = (SELECT Id FROM [dbo].[Roles] WHERE Name = 'Viewer')

-- Grant all permissions to Developer (including dashboard and settings)
INSERT INTO [dbo].[RolePermissions] ([RoleId], [ResourcePermissionId], [CreatedBy])
SELECT @DeveloperRoleId, [Id], 'SYSTEM'
FROM [dbo].[ResourcePermissions]
WHERE [PermissionKey] LIKE 'dashboard:%'
    OR [PermissionKey] LIKE 'serviceapplication:%'
    OR [PermissionKey] LIKE 'ruleset:%'
    OR [PermissionKey] LIKE 'servicerequestfile:%'
    OR [PermissionKey] LIKE 'servicetestcase:%'
    OR [PermissionKey] LIKE 'servicetestsuite:%'
    OR [PermissionKey] LIKE 'settings:%'
    OR [PermissionKey] LIKE 'user:%'
    OR [PermissionKey] LIKE 'role:%'
    OR [PermissionKey] LIKE 'permission:%'
    OR [PermissionKey] LIKE 'report:%'
    OR [PermissionKey] LIKE 'audit:%'
    OR [PermissionKey] LIKE 'system:%'

-- Grant all main resource permissions to Admin (excluding settings and system)
INSERT INTO [dbo].[RolePermissions] ([RoleId], [ResourcePermissionId], [CreatedBy])
SELECT @AdminRoleId, [Id], 'SYSTEM'
FROM [dbo].[ResourcePermissions]
WHERE [PermissionKey] LIKE 'dashboard:%'
    OR [PermissionKey] LIKE 'serviceapplication:%'
    OR [PermissionKey] LIKE 'ruleset:%'
    OR [PermissionKey] LIKE 'servicerequestfile:%'
    OR [PermissionKey] LIKE 'servicetestcase:%'
    OR [PermissionKey] LIKE 'servicetestsuite:%'
    OR [PermissionKey] LIKE 'user:%'
    OR [PermissionKey] LIKE 'role:%'
    OR [PermissionKey] LIKE 'permission:%'
    OR [PermissionKey] LIKE 'report:%'
    OR [PermissionKey] LIKE 'audit:%'
-- Exclude settings and system permissions

-- Grant read-only permissions to Viewer (including dashboard)
INSERT INTO [dbo].[RolePermissions] ([RoleId], [ResourcePermissionId], [CreatedBy])
SELECT @ViewerRoleId, [Id], 'SYSTEM'
FROM [dbo].[ResourcePermissions]
WHERE [PermissionKey] LIKE 'dashboard:%'
    OR [PermissionKey] LIKE 'serviceapplication:read'
    OR [PermissionKey] LIKE 'ruleset:read'
    OR [PermissionKey] LIKE 'servicerequestfile:read'
    OR [PermissionKey] LIKE 'servicetestcase:read'
    OR [PermissionKey] LIKE 'servicetestsuite:read'
    OR [PermissionKey] LIKE 'report:read'
    OR [PermissionKey] LIKE 'audit:read'
GO