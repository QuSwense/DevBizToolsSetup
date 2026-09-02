/*
    Table: RolePermissions
    Description: Stores role-based permissions for different features within the application.
    Logic:
    - Links roles to resource permissions
    - Role permissions provide baseline permissions for all users with that role
    - Individual user permissions can override role permissions
*/
CREATE TABLE [dbo].[RolePermissions] (
    -- Primary Key, Identity Column
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    -- Public Identifier for UI/Secure Operations (GUID)
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_RolePermissions_PublicId DEFAULT NEWID(),
    -- Foreign Key to Roles table (replaced Role string with RoleId)
    [RoleId] INT NOT NULL,
    -- Foreign Key to ResourcePermissions table
    [ResourcePermissionId] BIGINT NOT NULL,
    -- Indicates if the permission is granted to the role, default is true
    [IsGranted] BIT NOT NULL CONSTRAINT DF_RolePermissions_IsGranted DEFAULT 1,
    -- Indicates if the role permission is currently active, default is true
    [IsActive] BIT NOT NULL CONSTRAINT DF_RolePermissions_IsActive DEFAULT 1,
    -- Timestamps for auditing
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_RolePermissions_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT PK_RolePermissions PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_RolePermissions_PublicId UNIQUE ([PublicId] ASC),
    CONSTRAINT UQ_RolePermissions_RoleId_ResourcePermissionId UNIQUE ([RoleId] ASC, [ResourcePermissionId] ASC),

    -- Foreign Keys
    CONSTRAINT FK_RolePermissions_Roles_RoleId FOREIGN KEY ([RoleId]) REFERENCES [dbo].[Roles]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_RolePermissions_ResourcePermissions_ResourcePermissionId FOREIGN KEY ([ResourcePermissionId]) REFERENCES [dbo].[ResourcePermissions]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_RolePermissions_Users_CreatedBy FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_RolePermissions_Users_LastUpdatedBy FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
)
GO

CREATE NONCLUSTERED INDEX IX_RolePermissions_RoleId ON [dbo].[RolePermissions]([RoleId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_RolePermissions_ResourcePermissionId ON [dbo].[RolePermissions]([ResourcePermissionId] ASC)
GO