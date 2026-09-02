/*
    Table: RuleSetsPermissions
    Description: Stores permissions for rule sets, indicating which users or roles have access to specific rule sets.
    Logic:
    - When a user creates a rule set, they automatically become the owner
    - Permissions can be granted to individual users OR roles (not both)
    - Uses ResourcePermissions for granular access control
*/
CREATE TABLE [dbo].[RuleSetsPermissions] (
    -- Primary Key, Identity Column
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Public Identifier for UI/Secure Operations (GUID)
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_RuleSetsPermissions_PublicId DEFAULT NEWID(),
    -- Foreign Key to RuleSets table
    [RuleSetId] INT NOT NULL,
    -- User ID or Role ID (one must be provided, not both)
    [UserId] NVARCHAR(20) NULL,
    [RoleId] INT NULL,
    -- Foreign Key to ResourcePermissions table
    [ResourcePermissionId] BIGINT NOT NULL,
    -- Indicates if the permission is granted, default is true
    [IsGranted] BIT NOT NULL CONSTRAINT DF_RuleSetsPermissions_IsGranted DEFAULT 1,
    -- Indicates if the permission is active, default is true
    [IsActive] BIT NOT NULL CONSTRAINT DF_RuleSetsPermissions_IsActive DEFAULT 1,
    -- Timestamps for auditing
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_RuleSetsPermissions_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    -- Primary Key
    CONSTRAINT PK_RuleSetsPermissions PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_RuleSetsPermissions_PublicId UNIQUE ([PublicId] ASC),
    CONSTRAINT UQ_RuleSetsPermissions_RuleSetId_UserId_RoleId_ResourcePermissionId 
        UNIQUE ([RuleSetId] ASC, [UserId] ASC, [RoleId] ASC, [ResourcePermissionId] ASC),

    -- Check constraints
    CONSTRAINT CK_RuleSetsPermissions_UserOrRole 
        CHECK ([UserId] IS NOT NULL OR [RoleId] IS NOT NULL),
    CONSTRAINT CK_RuleSetsPermissions_NotBothUserAndRole 
        CHECK (NOT ([UserId] IS NOT NULL AND [RoleId] IS NOT NULL)),

    -- Foreign Keys
    CONSTRAINT FK_RuleSetsPermissions_RuleSets_RuleSetId
        FOREIGN KEY ([RuleSetId]) REFERENCES [dbo].[RuleSets]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_RuleSetsPermissions_Users_UserId
        FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users]([UserId]) ON DELETE CASCADE,
    CONSTRAINT FK_RuleSetsPermissions_Roles_RoleId
        FOREIGN KEY ([RoleId]) REFERENCES [dbo].[Roles]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_RuleSetsPermissions_ResourcePermissions_ResourcePermissionId
        FOREIGN KEY ([ResourcePermissionId]) REFERENCES [dbo].[ResourcePermissions]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_RuleSetsPermissions_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_RuleSetsPermissions_Users_LastUpdatedBy
        FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
)
GO

-- Performance Indexes
CREATE NONCLUSTERED INDEX IX_RuleSetsPermissions_RuleSetId
    ON [dbo].[RuleSetsPermissions]([RuleSetId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_RuleSetsPermissions_UserId
    ON [dbo].[RuleSetsPermissions]([UserId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_RuleSetsPermissions_RoleId
    ON [dbo].[RuleSetsPermissions]([RoleId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_RuleSetsPermissions_ResourcePermissionId
    ON [dbo].[RuleSetsPermissions]([ResourcePermissionId] ASC)
GO