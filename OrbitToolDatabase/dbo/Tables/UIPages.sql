/*
    Table: UIPages
    Description: Defines the UI navigation structure and pages available in the application.
    Logic:
    - Hierarchical structure using ParentId
    - Each page can have multiple permissions required for access
    - Supports conditional visibility based on feature flags
*/
CREATE TABLE [dbo].[UIPages] (
    -- Primary Key, Identity Column
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Public Identifier
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_UIPages_PublicId DEFAULT NEWID(),
    -- Parent page for hierarchical navigation (NULL for root)
    [ParentId] INT NULL,
    -- Page/Route name (e.g., 'Dashboard', 'ServiceApplications')
    [Name] NVARCHAR(100) NOT NULL,
    -- Required permission for viewing this page
    [ResourcePermissionId] BIGINT NOT NULL,
    -- Feature flag name (if feature-flagged)
    [FeatureFlag] NVARCHAR(100) NULL,
    -- Indicates if page is active
    [IsActive] BIT NOT NULL CONSTRAINT DF_UIPages_IsActive DEFAULT 1,
    -- Indicates if page is visible in navigation
    [IsVisibleInNav] BIT NOT NULL CONSTRAINT DF_UIPages_IsVisibleInNav DEFAULT 1,
    -- Timestamps for auditing
    [CreatedAt] DATETIME2(3) NOT NULL CONSTRAINT DF_UIPages_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME2(3) NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT PK_UIPages PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_UIPages_PublicId UNIQUE ([PublicId] ASC),
    CONSTRAINT UQ_UIPages_Name UNIQUE ([Name] ASC),

    -- Foreign Keys
    CONSTRAINT FK_UIPages_ParentId FOREIGN KEY ([ParentId]) REFERENCES [dbo].[UIPages]([Id]),
    CONSTRAINT FK_UIPages_ResourcePermissions FOREIGN KEY ([ResourcePermissionId]) REFERENCES [dbo].[ResourcePermissions]([Id]),
    CONSTRAINT FK_UIPages_Users_CreatedBy FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_UIPages_Users_LastUpdatedBy FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
);
GO

CREATE NONCLUSTERED INDEX IX_UIPages_ParentId
    ON [dbo].[UIPages]([ParentId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_UIPages_ResourcePermissionId
    ON [dbo].[UIPages]([ResourcePermissionId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_UIPages_IsActive
    ON [dbo].[UIPages]([IsActive] ASC)
GO