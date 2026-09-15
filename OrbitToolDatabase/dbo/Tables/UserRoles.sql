/*
    Table: UserRoles
    Description: Associates users with roles within the system.
*/
CREATE TABLE [dbo].[UserRoles]
(
    -- Primary Key, Identity Column
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Public Identifier
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_UserRoles_PublicId DEFAULT NEWID(),
    -- The AD User ID is used as the primary key to ensure uniqueness across the organization.
    [UserId] NVARCHAR(20) NOT NULL,
    -- The Role ID is used to associate the user with a specific role.
    [RoleId] INT NOT NULL,
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [CreatedAt] DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT PK_UserRoles PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_UserRoles_PublicId UNIQUE ([PublicId] ASC),
    CONSTRAINT UQ_UserRoles_UserId_RoleId UNIQUE ([UserId] ASC, [RoleId] ASC),

    CONSTRAINT FK_UserRoles_Users_UserId FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users]([UserId]) ON DELETE CASCADE,
    CONSTRAINT FK_UserRoles_Roles_RoleId FOREIGN KEY ([RoleId]) REFERENCES [dbo].[Roles]([Id]),
    CONSTRAINT FK_UserRoles_Users_CreatedBy FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId])
)
GO

CREATE NONCLUSTERED INDEX IX_UserRoles_RoleId
    ON [dbo].[UserRoles]([RoleId] ASC)
GO
