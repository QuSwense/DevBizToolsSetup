/*
    Seed Roles - System roles (Developer, Admin, Viewer)

    Idempotent: each role is inserted only if a role with that name does not exist.
    NOTE: The SYSTEM user must exist before running this script (Users.sql inserts
    SYSTEM with RoleId=NULL to break the circular FK dependency).
*/
IF NOT EXISTS (SELECT 1 FROM [dbo].[Roles] WHERE [Name] = N'Developer')
    INSERT INTO [dbo].[Roles] ([Name], [Description], [IsSystemRole], [CreatedBy])
    VALUES (N'Developer', N'Developer role with full access to all resources including settings', 1, N'SYSTEM');
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[Roles] WHERE [Name] = N'Admin')
    INSERT INTO [dbo].[Roles] ([Name], [Description], [IsSystemRole], [CreatedBy])
    VALUES (N'Admin', N'Administrator role with full access to main resource topics', 1, N'SYSTEM');
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[Roles] WHERE [Name] = N'Viewer')
    INSERT INTO [dbo].[Roles] ([Name], [Description], [IsSystemRole], [CreatedBy])
    VALUES (N'Viewer', N'Read-only access to all resources', 1, N'SYSTEM');
GO
