/*
    Seed ResourcePermissions - Including Dashboard permission
*/
INSERT INTO [dbo].[ResourcePermissions] ([PermissionKey], [CreatedBy])
VALUES 
    -- Dashboard (Special - doesn't require specific permission)
    ('dashboard:view', 'SYSTEM'),
    
    -- All other permissions as previously defined...
    ('serviceapplication:read', 'SYSTEM'),
    ('serviceapplication:write', 'SYSTEM'),
    ('serviceapplication:delete', 'SYSTEM'),
    ('serviceapplication:execute', 'SYSTEM'),
    ('serviceapplication:admin', 'SYSTEM'),
    ('serviceapplication:share', 'SYSTEM'),
    ('serviceapplication:test', 'SYSTEM'),
    ('serviceapplication:configure', 'SYSTEM'),
    
    ('ruleset:read', 'SYSTEM'),
    ('ruleset:write', 'SYSTEM'),
    ('ruleset:delete', 'SYSTEM'),
    ('ruleset:execute', 'SYSTEM'),
    ('ruleset:admin', 'SYSTEM'),
    ('ruleset:share', 'SYSTEM'),
    ('ruleset:publish', 'SYSTEM'),
    ('ruleset:version', 'SYSTEM'),
    
    ('servicerequestfile:read', 'SYSTEM'),
    ('servicerequestfile:write', 'SYSTEM'),
    ('servicerequestfile:delete', 'SYSTEM'),
    ('servicerequestfile:execute', 'SYSTEM'),
    ('servicerequestfile:admin', 'SYSTEM'),
    ('servicerequestfile:share', 'SYSTEM'),
    ('servicerequestfile:download', 'SYSTEM'),
    ('servicerequestfile:upload', 'SYSTEM'),
    
    ('servicetestcase:read', 'SYSTEM'),
    ('servicetestcase:write', 'SYSTEM'),
    ('servicetestcase:delete', 'SYSTEM'),
    ('servicetestcase:execute', 'SYSTEM'),
    ('servicetestcase:admin', 'SYSTEM'),
    ('servicetestcase:share', 'SYSTEM'),
    ('servicetestcase:run', 'SYSTEM'),
    ('servicetestcase:schedule', 'SYSTEM'),
    
    ('servicetestsuite:read', 'SYSTEM'),
    ('servicetestsuite:write', 'SYSTEM'),
    ('servicetestsuite:delete', 'SYSTEM'),
    ('servicetestsuite:execute', 'SYSTEM'),
    ('servicetestsuite:admin', 'SYSTEM'),
    ('servicetestsuite:share', 'SYSTEM'),
    ('servicetestsuite:run', 'SYSTEM'),
    ('servicetestsuite:schedule', 'SYSTEM'),
    
    ('settings:read', 'SYSTEM'),
    ('settings:write', 'SYSTEM'),
    ('settings:admin', 'SYSTEM'),
    
    ('user:read', 'SYSTEM'),
    ('user:write', 'SYSTEM'),
    ('user:delete', 'SYSTEM'),
    ('user:admin', 'SYSTEM'),
    
    ('role:read', 'SYSTEM'),
    ('role:write', 'SYSTEM'),
    ('role:delete', 'SYSTEM'),
    ('role:admin', 'SYSTEM'),
    
    ('permission:read', 'SYSTEM'),
    ('permission:write', 'SYSTEM'),
    ('permission:admin', 'SYSTEM'),
    
    ('report:read', 'SYSTEM'),
    ('report:generate', 'SYSTEM'),
    ('report:export', 'SYSTEM'),
    
    ('audit:read', 'SYSTEM'),
    ('audit:export', 'SYSTEM'),
    
    ('system:monitor', 'SYSTEM'),
    ('system:backup', 'SYSTEM'),
    ('system:restore', 'SYSTEM')
GO