/*
    Table: RolePermissions
    Description: Stores role-based permissions for different features within the application.
*/
CREATE TABLE [dbo].[RolePermissions] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    -- Role name, e.g., 'Developer', 'TestEngineer'
    [Role] NVARCHAR(50) NOT NULL,
    -- Foreign Key to ResourcePermissions table, linking the user permission to a specific resource permission
    [ResourcePermissionId] BIGINT NOT NULL,
    -- Indicates if the permission is granted to the role, default is true
    [IsGranted] BIT NOT NULL CONSTRAINT DF_RolePermissions_IsGranted DEFAULT 1,
    -- Indicates if the role permission is currently active, default is true
    [IsActive] BIT NOT NULL CONSTRAINT DF_RolePermissions_IsActive DEFAULT 1,
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_RolePermissions_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT PK_RolePermissions PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_RolePermissions_Role_ResourcePermissionId UNIQUE ([Role] ASC, [ResourcePermissionId] ASC),

    -- Foreign Keys
    CONSTRAINT FK_RolePermissions_ResourcePermissions_ResourcePermissionId FOREIGN KEY ([ResourcePermissionId]) REFERENCES [dbo].[ResourcePermissions]([Id]),
    CONSTRAINT FK_RolePermissions_Users_CreatedBy FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_RolePermissions_Users_LastUpdatedBy FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
);
