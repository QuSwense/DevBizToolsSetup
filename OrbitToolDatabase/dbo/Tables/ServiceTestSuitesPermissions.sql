/*
    Table: ServiceTestSuitesPermissions
    Description: Stores permissions for service test suites, indicating which users or roles have access to specific test suites.
    Logic:
    - When a user creates a service test suite, they automatically become the owner
    - Permissions can be granted to individual users OR roles (not both)
    - Uses ResourcePermissions for granular access control
*/
CREATE TABLE [dbo].[ServiceTestSuitesPermissions] (
    -- Primary Key, Identity Column
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Public Identifier for UI/Secure Operations (GUID)
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_ServiceTestSuitesPermissions_PublicId DEFAULT NEWID(),
    -- Foreign Key to ServiceTestSuites table
    [ServiceTestSuiteId] INT NOT NULL,
    -- User ID or Role ID (one must be provided, not both)
    [UserId] NVARCHAR(20) NULL,
    [RoleId] INT NULL,
    -- Foreign Key to ResourcePermissions table
    [ResourcePermissionId] BIGINT NOT NULL,
    -- Indicates if the permission is granted, default is true
    [IsGranted] BIT NOT NULL CONSTRAINT DF_ServiceTestSuitesPermissions_IsGranted DEFAULT 1,
    -- Indicates if the permission is active, default is true
    [IsActive] BIT NOT NULL CONSTRAINT DF_ServiceTestSuitesPermissions_IsActive DEFAULT 1,
    -- Timestamps for auditing
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceTestSuitesPermissions_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    -- Primary Key
    CONSTRAINT PK_ServiceTestSuitesPermissions PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_ServiceTestSuitesPermissions_PublicId UNIQUE ([PublicId] ASC),
    CONSTRAINT UQ_ServiceTestSuitesPermissions_SuiteId_UserId_RoleId_ResourcePermissionId 
        UNIQUE ([ServiceTestSuiteId] ASC, [UserId] ASC, [RoleId] ASC, [ResourcePermissionId] ASC),

    -- Check constraints
    CONSTRAINT CK_ServiceTestSuitesPermissions_UserOrRole 
        CHECK ([UserId] IS NOT NULL OR [RoleId] IS NOT NULL),
    CONSTRAINT CK_ServiceTestSuitesPermissions_NotBothUserAndRole 
        CHECK (NOT ([UserId] IS NOT NULL AND [RoleId] IS NOT NULL)),

    -- Foreign Keys
    CONSTRAINT FK_ServiceTestSuitesPermissions_ServiceTestSuites_SuiteId
        FOREIGN KEY ([ServiceTestSuiteId]) REFERENCES [dbo].[ServiceTestSuites]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceTestSuitesPermissions_Users_UserId
        FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users]([UserId]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceTestSuitesPermissions_Roles_RoleId
        FOREIGN KEY ([RoleId]) REFERENCES [dbo].[Roles]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceTestSuitesPermissions_ResourcePermissions_ResourcePermissionId
        FOREIGN KEY ([ResourcePermissionId]) REFERENCES [dbo].[ResourcePermissions]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceTestSuitesPermissions_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_ServiceTestSuitesPermissions_Users_LastUpdatedBy
        FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
)
GO

-- Performance Indexes
CREATE NONCLUSTERED INDEX IX_ServiceTestSuitesPermissions_SuiteId
    ON [dbo].[ServiceTestSuitesPermissions]([ServiceTestSuiteId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_ServiceTestSuitesPermissions_UserId
    ON [dbo].[ServiceTestSuitesPermissions]([UserId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_ServiceTestSuitesPermissions_RoleId
    ON [dbo].[ServiceTestSuitesPermissions]([RoleId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_ServiceTestSuitesPermissions_ResourcePermissionId
    ON [dbo].[ServiceTestSuitesPermissions]([ResourcePermissionId] ASC)
GO