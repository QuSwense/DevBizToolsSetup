/*
    Table: ServiceAppPermissions
    Description: Stores permissions for service applications, indicating which users or roles have access to specific service applications.
    Logic:
    - When a user creates a service application, they automatically become the owner
    - Permissions can be granted to individual users OR roles (not both)
    - Uses ResourcePermissions for granular access control
*/
CREATE TABLE [dbo].[ServiceAppPermissions] (
    -- Primary Key, Identity Column
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Public Identifier for UI/Secure Operations (GUID)
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_ServiceAppPermissions_PublicId DEFAULT NEWID(),
    -- Foreign Key to ServiceApplications table
    [ServiceApplicationId] INT NOT NULL,
    -- User ID or Role ID (one must be provided, not both)
    [UserId] NVARCHAR(20) NULL,
    [RoleId] INT NULL,
    -- Foreign Key to ResourcePermissions table
    [ResourcePermissionId] BIGINT NOT NULL,
    -- Indicates if the permission is granted, default is true
    [IsGranted] BIT NOT NULL CONSTRAINT DF_ServiceAppPermissions_IsGranted DEFAULT 1,
    -- Indicates if the permission is active, default is true
    [IsActive] BIT NOT NULL CONSTRAINT DF_ServiceAppPermissions_IsActive DEFAULT 1,
    -- Timestamps for auditing
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceAppPermissions_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    -- Primary Key
    CONSTRAINT PK_ServiceAppPermissions PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_ServiceAppPermissions_PublicId UNIQUE ([PublicId] ASC),
    CONSTRAINT UQ_ServiceAppPermissions_AppId_UserId_RoleId_ResourcePermissionId 
        UNIQUE ([ServiceApplicationId] ASC, [UserId] ASC, [RoleId] ASC, [ResourcePermissionId] ASC),

    -- Check constraints
    CONSTRAINT CK_ServiceAppPermissions_UserOrRole 
        CHECK ([UserId] IS NOT NULL OR [RoleId] IS NOT NULL),
    CONSTRAINT CK_ServiceAppPermissions_NotBothUserAndRole 
        CHECK (NOT ([UserId] IS NOT NULL AND [RoleId] IS NOT NULL)),

    -- Foreign Keys
    CONSTRAINT FK_ServiceAppPermissions_ServiceApplications_AppId
        FOREIGN KEY ([ServiceApplicationId]) REFERENCES [dbo].[ServiceApplications]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceAppPermissions_Users_UserId
        FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users]([UserId]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceAppPermissions_Roles_RoleId
        FOREIGN KEY ([RoleId]) REFERENCES [dbo].[Roles]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceAppPermissions_ResourcePermissions_ResourcePermissionId
        FOREIGN KEY ([ResourcePermissionId]) REFERENCES [dbo].[ResourcePermissions]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceAppPermissions_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_ServiceAppPermissions_Users_LastUpdatedBy
        FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
)
GO

-- Performance Indexes
CREATE NONCLUSTERED INDEX IX_ServiceAppPermissions_ServiceApplicationId
    ON [dbo].[ServiceAppPermissions]([ServiceApplicationId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_ServiceAppPermissions_UserId
    ON [dbo].[ServiceAppPermissions]([UserId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_ServiceAppPermissions_RoleId
    ON [dbo].[ServiceAppPermissions]([RoleId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_ServiceAppPermissions_ResourcePermissionId
    ON [dbo].[ServiceAppPermissions]([ResourcePermissionId] ASC)
GO