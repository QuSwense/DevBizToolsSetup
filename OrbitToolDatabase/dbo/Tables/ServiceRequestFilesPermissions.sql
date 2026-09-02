/*
    Table: ServiceRequestFilesPermissions
    Description: Stores permissions for service request files, indicating which users or roles have access to specific files.
    Logic:
    - When a user creates a service request file, they automatically become the owner
    - Permissions can be granted to individual users OR roles (not both)
    - Uses ResourcePermissions for granular access control
*/
CREATE TABLE [dbo].[ServiceRequestFilesPermissions] (
    -- Primary Key, Identity Column
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Public Identifier for UI/Secure Operations (GUID)
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_ServiceRequestFilesPermissions_PublicId DEFAULT NEWID(),
    -- Foreign Key to ServiceRequestFiles table
    [ServiceRequestFileId] INT NOT NULL,
    -- User ID or Role ID (one must be provided, not both)
    [UserId] NVARCHAR(20) NULL,
    [RoleId] INT NULL,
    -- Foreign Key to ResourcePermissions table
    [ResourcePermissionId] BIGINT NOT NULL,
    -- Indicates if the permission is granted, default is true
    [IsGranted] BIT NOT NULL CONSTRAINT DF_ServiceRequestFilesPermissions_IsGranted DEFAULT 1,
    -- Indicates if the permission is active, default is true
    [IsActive] BIT NOT NULL CONSTRAINT DF_ServiceRequestFilesPermissions_IsActive DEFAULT 1,
    -- Timestamps for auditing
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceRequestFilesPermissions_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    -- Primary Key
    CONSTRAINT PK_ServiceRequestFilesPermissions PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_ServiceRequestFilesPermissions_PublicId UNIQUE ([PublicId] ASC),
    CONSTRAINT UQ_ServiceRequestFilesPermissions_FileId_UserId_RoleId_ResourcePermissionId 
        UNIQUE ([ServiceRequestFileId] ASC, [UserId] ASC, [RoleId] ASC, [ResourcePermissionId] ASC),

    -- Check constraints
    CONSTRAINT CK_ServiceRequestFilesPermissions_UserOrRole 
        CHECK ([UserId] IS NOT NULL OR [RoleId] IS NOT NULL),
    CONSTRAINT CK_ServiceRequestFilesPermissions_NotBothUserAndRole 
        CHECK (NOT ([UserId] IS NOT NULL AND [RoleId] IS NOT NULL)),

    -- Foreign Keys
    CONSTRAINT FK_ServiceRequestFilesPermissions_ServiceRequestFiles_FileId
        FOREIGN KEY ([ServiceRequestFileId]) REFERENCES [dbo].[ServiceRequestFiles]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceRequestFilesPermissions_Users_UserId
        FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users]([UserId]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceRequestFilesPermissions_Roles_RoleId
        FOREIGN KEY ([RoleId]) REFERENCES [dbo].[Roles]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceRequestFilesPermissions_ResourcePermissions_ResourcePermissionId
        FOREIGN KEY ([ResourcePermissionId]) REFERENCES [dbo].[ResourcePermissions]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceRequestFilesPermissions_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_ServiceRequestFilesPermissions_Users_LastUpdatedBy
        FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
)
GO

-- Performance Indexes
CREATE NONCLUSTERED INDEX IX_ServiceRequestFilesPermissions_FileId
    ON [dbo].[ServiceRequestFilesPermissions]([ServiceRequestFileId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_ServiceRequestFilesPermissions_UserId
    ON [dbo].[ServiceRequestFilesPermissions]([UserId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_ServiceRequestFilesPermissions_RoleId
    ON [dbo].[ServiceRequestFilesPermissions]([RoleId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_ServiceRequestFilesPermissions_ResourcePermissionId
    ON [dbo].[ServiceRequestFilesPermissions]([ResourcePermissionId] ASC)
GO