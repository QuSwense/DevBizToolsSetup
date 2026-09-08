/*
    Seed Users - Users related to System roles (Developer, Admin, Viewer)

    Idempotent: each user is inserted only if a user with that UserId does not exist.
    NOTE: The SYSTEM user is inserted with RoleId = NULL and CreatedBy = NULL to break
    the circular FK dependency (Roles.CreatedBy -> Users.UserId, Users.RoleId -> Roles.Id).
    The RunSeeds.sql script updates the RoleId after Roles are seeded.
*/
IF NOT EXISTS (SELECT 1 FROM [dbo].[Users] WHERE [UserId] = 'SYSTEM')
BEGIN
    INSERT INTO [dbo].[Users] ([UserId], [Email], [Department], [FirstName], [LastName], [RoleId], [CreatedBy])
    VALUES ('SYSTEM', 'system@example.com', 'IT', 'System', 'User', NULL, NULL);
END
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[Users] WHERE [UserId] = 'test_soap_user1')
BEGIN
    INSERT INTO [dbo].[Users] ([UserId], [Email], [Department], [FirstName], [LastName], [RoleId], [CreatedBy])
    VALUES ('test_soap_user1', 'test_soap_user1@example.com', 'IT', 'Test1', 'SoapUser1', (SELECT [Id] FROM [dbo].[Roles] WHERE [Name] = N'Admin'), 'SYSTEM');
END
GO