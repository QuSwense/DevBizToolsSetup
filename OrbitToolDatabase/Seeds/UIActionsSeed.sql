/*
    Seed UIActions - UI Buttons and Operations
    NOTE: ResourcePermissions and UIPages must be seeded BEFORE this script.
    Uses subqueries to resolve permission keys to ResourcePermissions.Id.
*/
INSERT INTO [dbo].[UIActions] 
    ([PageId], [ActionName], [DisplayName], [ResourcePermissionsId], [ActionType], [UiElementId], [CreatedBy])
VALUES 
    -- ============================================
    -- Service Application Actions
    -- ============================================
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'ServiceApplicationsList'), 
        'Create', 'Create New Application', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'serviceapplication:write'), 'Button', 'btnCreateApp', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'ServiceApplicationsList'), 
        'Edit', 'Edit Application', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'serviceapplication:write'), 'Button', 'btnEditApp', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'ServiceApplicationsList'), 
        'Delete', 'Delete Application', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'serviceapplication:delete'), 'Button', 'btnDeleteApp', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'ServiceApplicationsList'), 
        'Share', 'Share Application', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'serviceapplication:share'), 'Button', 'btnShareApp', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'ServiceApplicationsList'), 
        'Test', 'Test Application', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'serviceapplication:test'), 'Button', 'btnTestApp', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'ServiceApplicationsList'), 
        'Export', 'Export Application', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'serviceapplication:read'), 'Button', 'btnExportApp', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'ServiceApplicationsList'), 
        'Configure', 'Configure Application', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'serviceapplication:configure'), 'Button', 'btnConfigureApp', 'SYSTEM'),

    -- ============================================
    -- Rule Set Actions
    -- ============================================
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'RuleSetsList'), 
        'Create', 'Create New Rule Set', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'ruleset:write'), 'Button', 'btnCreateRule', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'RuleSetsList'), 
        'Edit', 'Edit Rule Set', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'ruleset:write'), 'Button', 'btnEditRule', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'RuleSetsList'), 
        'Delete', 'Delete Rule Set', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'ruleset:delete'), 'Button', 'btnDeleteRule', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'RuleSetsList'), 
        'Test', 'Test Rule Set', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'ruleset:execute'), 'Button', 'btnTestRule', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'RuleSetsList'), 
        'Share', 'Share Rule Set', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'ruleset:share'), 'Button', 'btnShareRule', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'RuleSetsList'), 
        'Publish', 'Publish Rule Set', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'ruleset:publish'), 'Button', 'btnPublishRule', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'RuleSetsList'), 
        'Version', 'Version Management', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'ruleset:version'), 'Button', 'btnVersionRule', 'SYSTEM'),

    -- ============================================
    -- Service Request File Actions
    -- ============================================
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'ServiceRequestFilesList'), 
        'Upload', 'Upload File', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicerequestfile:upload'), 'Button', 'btnUploadFile', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'ServiceRequestFilesList'), 
        'Download', 'Download File', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicerequestfile:download'), 'Button', 'btnDownloadFile', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'ServiceRequestFilesList'), 
        'Edit', 'Edit File', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicerequestfile:write'), 'Button', 'btnEditFile', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'ServiceRequestFilesList'), 
        'Delete', 'Delete File', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicerequestfile:delete'), 'Button', 'btnDeleteFile', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'ServiceRequestFilesList'), 
        'Share', 'Share File', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicerequestfile:share'), 'Button', 'btnShareFile', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'ServiceRequestFilesList'), 
        'Execute', 'Execute File', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicerequestfile:execute'), 'Button', 'btnExecuteFile', 'SYSTEM'),

    -- ============================================
    -- Test Suite Actions
    -- ============================================
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'TestSuites'), 
        'Create', 'Create Test Suite', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicetestsuite:write'), 'Button', 'btnCreateSuite', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'TestSuites'), 
        'Edit', 'Edit Test Suite', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicetestsuite:write'), 'Button', 'btnEditSuite', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'TestSuites'), 
        'Delete', 'Delete Test Suite', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicetestsuite:delete'), 'Button', 'btnDeleteSuite', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'TestSuites'), 
        'Share', 'Share Test Suite', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicetestsuite:share'), 'Button', 'btnShareSuite', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'TestSuites'), 
        'Run', 'Run Test Suite', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicetestsuite:execute'), 'Button', 'btnRunSuite', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'TestSuites'), 
        'Schedule', 'Schedule Test Suite', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicetestsuite:schedule'), 'Button', 'btnScheduleSuite', 'SYSTEM'),

    -- ============================================
    -- Test Case Actions
    -- ============================================
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'TestCases'), 
        'Create', 'Create Test Case', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicetestcase:write'), 'Button', 'btnCreateCase', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'TestCases'), 
        'Edit', 'Edit Test Case', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicetestcase:write'), 'Button', 'btnEditCase', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'TestCases'), 
        'Delete', 'Delete Test Case', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicetestcase:delete'), 'Button', 'btnDeleteCase', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'TestCases'), 
        'Share', 'Share Test Case', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicetestcase:share'), 'Button', 'btnShareCase', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'TestCases'), 
        'Run', 'Run Test Case', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicetestcase:execute'), 'Button', 'btnRunCase', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'TestCases'), 
        'Schedule', 'Schedule Test Case', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'servicetestcase:schedule'), 'Button', 'btnScheduleCase', 'SYSTEM'),

    -- ============================================
    -- Report Actions
    -- ============================================
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'TestReports'), 
        'Generate', 'Generate Report', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'report:generate'), 'Button', 'btnGenerateReport', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'TestReports'), 
        'Export', 'Export Report', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'report:export'), 'Button', 'btnExportReport', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'AuditReports'), 
        'Export', 'Export Audit Logs', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'audit:export'), 'Button', 'btnExportAudit', 'SYSTEM'),

    -- ============================================
    -- Settings Actions
    -- ============================================
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'GeneralSettings'), 
        'Save', 'Save Settings', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'settings:write'), 'Button', 'btnSaveSettings', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'GeneralSettings'), 
        'Reset', 'Reset Settings', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'settings:write'), 'Button', 'btnResetSettings', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'SecuritySettings'), 
        'Save', 'Save Security Settings', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'settings:admin'), 'Button', 'btnSaveSecurity', 'SYSTEM'),

    -- ============================================
    -- Administration Actions
    -- ============================================
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'UserManagement'), 
        'Create', 'Create User', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'user:write'), 'Button', 'btnCreateUser', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'UserManagement'), 
        'Edit', 'Edit User', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'user:write'), 'Button', 'btnEditUser', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'UserManagement'), 
        'Delete', 'Delete User', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'user:delete'), 'Button', 'btnDeleteUser', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'RoleManagement'), 
        'Create', 'Create Role', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'role:write'), 'Button', 'btnCreateRole', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'RoleManagement'), 
        'Edit', 'Edit Role', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'role:write'), 'Button', 'btnEditRole', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'RoleManagement'), 
        'Delete', 'Delete Role', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'role:delete'), 'Button', 'btnDeleteRole', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'PermissionManagement'), 
        'Edit', 'Edit Permissions', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'permission:write'), 'Button', 'btnEditPermissions', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'SystemBackup'), 
        'CreateBackup', 'Create Backup', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'system:backup'), 'Button', 'btnBackup', 'SYSTEM'),
    ((SELECT Id FROM [dbo].[UIPages] WHERE Name = 'SystemBackup'), 
        'Restore', 'Restore Backup', (SELECT Id FROM [dbo].[ResourcePermissions] WHERE [PermissionKey] = 'system:restore'), 'Button', 'btnRestore', 'SYSTEM')
GO