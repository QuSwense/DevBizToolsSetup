/*
    Table: ServiceTestCasesPermissions
    Description: Stores permissions for service test cases, indicating which users or roles have access to specific test cases.
    Logic:
    - When a user creates a service test case, they automatically become the owner
    - Permissions can be granted to individual users OR roles (not both)
    - Uses ResourcePermissions for granular access control
*/
CREATE TABLE [dbo].[ServiceTestCasesPermissions] (
    -- Primary Key, Identity Column
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Public Identifier for UI/Secure Operations (GUID)
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_ServiceTestCasesPermissions_PublicId DEFAULT NEWID(),
    -- Foreign Key to ServiceTestCases table
    [ServiceTestCaseId] INT NOT NULL,
    -- User ID or Role ID (one must be provided, not both)
    [UserId] NVARCHAR(20) NULL,
    [RoleId] INT NULL,
    -- Foreign Key to ResourcePermissions table
    [ResourcePermissionId] BIGINT NOT NULL,
    -- Indicates if the permission is granted, default is true
    [IsGranted] BIT NOT NULL CONSTRAINT DF_ServiceTestCasesPermissions_IsGranted DEFAULT 1,
    -- Indicates if the permission is active, default is true
    [IsActive] BIT NOT NULL CONSTRAINT DF_ServiceTestCasesPermissions_IsActive DEFAULT 1,
    -- Timestamps for auditing
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceTestCasesPermissions_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    -- Primary Key
    CONSTRAINT PK_ServiceTestCasesPermissions PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_ServiceTestCasesPermissions_PublicId UNIQUE ([PublicId] ASC),
    CONSTRAINT UQ_ServiceTestCasesPermissions_TestCaseId_UserId_RoleId_ResourcePermissionId 
        UNIQUE ([ServiceTestCaseId] ASC, [UserId] ASC, [RoleId] ASC, [ResourcePermissionId] ASC),

    -- Check constraints
    CONSTRAINT CK_ServiceTestCasesPermissions_UserOrRole 
        CHECK ([UserId] IS NOT NULL OR [RoleId] IS NOT NULL),
    CONSTRAINT CK_ServiceTestCasesPermissions_NotBothUserAndRole 
        CHECK (NOT ([UserId] IS NOT NULL AND [RoleId] IS NOT NULL)),

    -- Foreign Keys
    CONSTRAINT FK_ServiceTestCasesPermissions_ServiceTestCases_TestCaseId
        FOREIGN KEY ([ServiceTestCaseId]) REFERENCES [dbo].[ServiceTestCases]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceTestCasesPermissions_Users_UserId
        FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users]([UserId]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceTestCasesPermissions_Roles_RoleId
        FOREIGN KEY ([RoleId]) REFERENCES [dbo].[Roles]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceTestCasesPermissions_ResourcePermissions_ResourcePermissionId
        FOREIGN KEY ([ResourcePermissionId]) REFERENCES [dbo].[ResourcePermissions]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceTestCasesPermissions_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_ServiceTestCasesPermissions_Users_LastUpdatedBy
        FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
)
GO

-- Performance Indexes
CREATE NONCLUSTERED INDEX IX_ServiceTestCasesPermissions_TestCaseId
    ON [dbo].[ServiceTestCasesPermissions]([ServiceTestCaseId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_ServiceTestCasesPermissions_UserId
    ON [dbo].[ServiceTestCasesPermissions]([UserId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_ServiceTestCasesPermissions_RoleId
    ON [dbo].[ServiceTestCasesPermissions]([RoleId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_ServiceTestCasesPermissions_ResourcePermissionId
    ON [dbo].[ServiceTestCasesPermissions]([ResourcePermissionId] ASC)
GO