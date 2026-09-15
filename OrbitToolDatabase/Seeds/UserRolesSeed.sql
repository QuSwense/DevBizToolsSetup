/*
    Seed UserRoles - Role assignments for seeded users

    Idempotent: each link is inserted only if that (UserId, RoleId) pair does not exist.
    NOTE: This replaces the old Users.RoleId column. Run after UsersSeed.sql and
    RolesSeed.sql so both the user and the role exist.
*/
IF NOT EXISTS (
    SELECT 1
    FROM [dbo].[UserRoles]
    WHERE [UserId] = N'SYSTEM'
      AND [RoleId] = (SELECT [Id] FROM [dbo].[Roles] WHERE [Name] = N'Developer')
)
BEGIN
    INSERT INTO [dbo].[UserRoles] ([UserId], [RoleId], [CreatedBy])
    VALUES (N'SYSTEM', (SELECT [Id] FROM [dbo].[Roles] WHERE [Name] = N'Developer'), N'SYSTEM');
END
GO

IF NOT EXISTS (
    SELECT 1
    FROM [dbo].[UserRoles]
    WHERE [UserId] = N'test_soap_user1'
      AND [RoleId] = (SELECT [Id] FROM [dbo].[Roles] WHERE [Name] = N'Admin')
)
BEGIN
    INSERT INTO [dbo].[UserRoles] ([UserId], [RoleId], [CreatedBy])
    VALUES (N'test_soap_user1', (SELECT [Id] FROM [dbo].[Roles] WHERE [Name] = N'Admin'), N'SYSTEM');
END
GO
