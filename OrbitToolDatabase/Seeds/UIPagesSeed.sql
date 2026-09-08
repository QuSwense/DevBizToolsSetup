/*
    Seed UIPages - Hierarchical Navigation Structure
    NOTE: ResourcePermissions must be seeded BEFORE this script.
    Uses subqueries to resolve permission keys to ResourcePermissions.Id.
*/
INSERT INTO [dbo].[UIPages] 
    ([ParentId], [Name], [ResourcePermissionsId], [FeatureFlag], [IsVisibleInNav], [CreatedBy])
VALUES 
    -- ============================================
    -- Root Level Pages (Level 0)
    -- ============================================
    (NULL, 'Dashboard', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'dashboard:view'), NULL, 1, 'SYSTEM'),
    (NULL, 'ServiceApplications', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'serviceapplication:read'), NULL, 1, 'SYSTEM'),
    (NULL, 'RuleSets', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'ruleset:read'), NULL, 1, 'SYSTEM'),
    (NULL, 'ServiceRequestFiles', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicerequestfile:read'), NULL, 1, 'SYSTEM'),
    (NULL, 'TestManagement', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicetestcase:read'), NULL, 1, 'SYSTEM'),
    (NULL, 'Reports', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'report:read'), NULL, 1, 'SYSTEM'),
    (NULL, 'Settings', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'settings:read'), NULL, 1, 'SYSTEM'),
    (NULL, 'Administration', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'permission:read'), 'EnableAdminModule', 1, 'SYSTEM'),

    -- ============================================
    -- Service Applications Sub-Pages (Level 1)
    -- ============================================
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'ServiceApplications'), 
        'ServiceApplicationsList', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'serviceapplication:read'), NULL, 1, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'ServiceApplications'), 
        'ServiceApplicationsCreate', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'serviceapplication:write'), NULL, 0, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'ServiceApplications'), 
        'ServiceApplicationsEdit', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'serviceapplication:write'), NULL, 0, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'ServiceApplications'), 
        'ServiceApplicationsShare', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'serviceapplication:share'), NULL, 0, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'ServiceApplications'), 
        'ServiceApplicationsTest', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'serviceapplication:test'), NULL, 0, 'SYSTEM'),

    -- ============================================
    -- Rule Sets Sub-Pages (Level 1)
    -- ============================================
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'RuleSets'), 
        'RuleSetsList', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'ruleset:read'), NULL, 1, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'RuleSets'), 
        'RuleSetsCreate', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'ruleset:write'), NULL, 0, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'RuleSets'), 
        'RuleSetsEdit', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'ruleset:write'), NULL, 0, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'RuleSets'), 
        'RuleSetsTest', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'ruleset:execute'), NULL, 0, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'RuleSets'), 
        'RuleSetsShare', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'ruleset:share'), NULL, 0, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'RuleSets'), 
        'RuleSetsPublish', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'ruleset:publish'), NULL, 0, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'RuleSets'), 
        'RuleSetsVersion', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'ruleset:version'), NULL, 0, 'SYSTEM'),

    -- ============================================
    -- Service Request Files Sub-Pages (Level 1)
    -- ============================================
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'ServiceRequestFiles'), 
        'ServiceRequestFilesList', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicerequestfile:read'), NULL, 1, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'ServiceRequestFiles'), 
        'ServiceRequestFilesUpload', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicerequestfile:upload'), NULL, 0, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'ServiceRequestFiles'), 
        'ServiceRequestFilesDownload', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicerequestfile:download'), NULL, 0, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'ServiceRequestFiles'), 
        'ServiceRequestFilesEdit', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicerequestfile:write'), NULL, 0, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'ServiceRequestFiles'), 
        'ServiceRequestFilesShare', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicerequestfile:share'), NULL, 0, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'ServiceRequestFiles'), 
        'ServiceRequestFilesExecute', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicerequestfile:execute'), NULL, 0, 'SYSTEM'),

    -- ============================================
    -- Test Management Sub-Pages (Level 1)
    -- ============================================
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'TestManagement'), 
        'TestSuites', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicetestsuite:read'), NULL, 1, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'TestManagement'), 
        'TestCases', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicetestcase:read'), NULL, 1, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'TestManagement'), 
        'TestExecution', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicetestcase:execute'), NULL, 1, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'TestManagement'), 
        'TestResults', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicetestcase:read'), NULL, 1, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'TestManagement'), 
        'TestSuiteCreate', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicetestsuite:write'), NULL, 0, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'TestManagement'), 
        'TestSuiteEdit', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicetestsuite:write'), NULL, 0, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'TestManagement'), 
        'TestSuiteShare', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicetestsuite:share'), NULL, 0, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'TestManagement'), 
        'TestCaseCreate', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicetestcase:write'), NULL, 0, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'TestManagement'), 
        'TestCaseEdit', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicetestcase:write'), NULL, 0, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'TestManagement'), 
        'TestCaseShare', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicetestcase:share'), NULL, 0, 'SYSTEM'),

    -- ============================================
    -- Reports Sub-Pages (Level 1)
    -- ============================================
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'Reports'), 
        'TestReports', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'report:read'), NULL, 1, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'Reports'), 
        'AuditReports', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'audit:read'), NULL, 1, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'Reports'), 
        'SystemReports', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'report:read'), NULL, 1, 'SYSTEM'),

    -- ============================================
    -- Settings Sub-Pages (Level 1)
    -- ============================================
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'Settings'), 
        'GeneralSettings', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'settings:write'), NULL, 1, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'Settings'), 
        'SecuritySettings', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'settings:admin'), NULL, 1, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'Settings'), 
        'IntegrationSettings', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'settings:write'), NULL, 1, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'Settings'), 
        'NotificationSettings', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'settings:write'), NULL, 1, 'SYSTEM'),

    -- ============================================
    -- Administration Sub-Pages (Level 1)
    -- ============================================
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'Administration'), 
        'UserManagement', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'user:read'), NULL, 1, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'Administration'), 
        'RoleManagement', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'role:read'), NULL, 1, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'Administration'), 
        'PermissionManagement', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'permission:read'), NULL, 1, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'Administration'), 
        'SystemHealth', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'system:monitor'), NULL, 1, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'Administration'), 
        'AuditLogs', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'audit:read'), NULL, 1, 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'Administration'), 
        'SystemBackup', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'system:backup'), NULL, 1, 'SYSTEM')
GO