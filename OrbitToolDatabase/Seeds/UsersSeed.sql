/*
    Seed Users - Users related to System roles (Developer, Admin, Viewer)

    Idempotent: each user is inserted only if a user with that UserId does not exist.
    NOTE: Users no longer carries a RoleId column. Role assignment is now modelled by
    the UserRoles junction table, so the SYSTEM user is inserted with CreatedBy = NULL
    and its role link is created in UserRolesSeed.sql after Roles are seeded.
*/
IF NOT EXISTS (SELECT 1 FROM [dbo].[Users] WHERE [UserId] = 'SYSTEM')
BEGIN
    INSERT INTO [dbo].[Users] ([UserId], [Email], [Department], [FirstName], [LastName], [CreatedBy])
    VALUES ('SYSTEM', 'system@example.com', 'IT', 'System', 'User', NULL);
END
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[Users] WHERE [UserId] = 'test_soap_user1')
BEGIN
    INSERT INTO [dbo].[Users] ([UserId], [Email], [Department], [FirstName], [LastName], [CreatedBy])
    VALUES ('test_soap_user1', 'test_soap_user1@example.com', 'IT', 'Test1', 'SoapUser1', 'SYSTEM');
END
GO