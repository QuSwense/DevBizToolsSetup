/*
    Table: UserPermissions
    Description: Stores user-specific permissions for different features within the application.
*/
CREATE TABLE [dbo].[UserPermissions] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    -- Public Identifier for UI/Secure Operations (GUID)
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_UserPermissions_PublicId DEFAULT NEWID(),
    -- User ID, e.g., 'jdoe', 'asmith'
    [UserId] NVARCHAR(20) NOT NULL,
    -- Foreign Key to ResourcePermissions table, linking the user permission to a specific resource permission
    [ResourcePermissionId] BIGINT NOT NULL,
    -- Indicates if the permission is granted to the user, default is true
    [IsGranted] BIT NOT NULL CONSTRAINT DF_UserPermissions_IsGranted DEFAULT 1,
    -- Indicates if the user permission is currently active, default is true
    [IsActive] BIT NOT NULL CONSTRAINT DF_UserPermissions_IsActive DEFAULT 1,
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_UserPermissions_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT PK_UserPermissions PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_UserPermissions_UserId_ResourcePermissionId UNIQUE ([UserId] ASC, [ResourcePermissionId] ASC),
    CONSTRAINT UQ_UserPermissions_PublicId UNIQUE ([PublicId] ASC),

    -- Foreign Keys
    CONSTRAINT FK_UserPermissions_ResourcePermissions_ResourcePermissionId FOREIGN KEY ([ResourcePermissionId]) REFERENCES [dbo].[ResourcePermissions]([Id]),
    CONSTRAINT FK_UserPermissions_Users_UserId FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_UserPermissions_Users_CreatedBy FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_UserPermissions_Users_LastUpdatedBy FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
);
