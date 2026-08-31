-- ==========================================
-- Configuration & Initialization
-- ==========================================
-- Set @DropAndRecreateAll = 1 to drop all existing tables/FKs and recreate everything.
-- Set @DropAndRecreateAll = 0 to execute in safe incremental mode.
DECLARE @DropAndRecreateAll BIT = 0;

IF NOT EXISTS (
    SELECT [name] 
    FROM [sys].[databases] 
    WHERE [name] = N'ServiceHubDb'
)
BEGIN
    CREATE DATABASE [ServiceHubDb];
END
GO

USE [ServiceHubDb];
GO

-- ==========================================
-- Optional Tear-Down (Drop FKs and Tables)
-- ==========================================
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'SoapOperations')
BEGIN
    -- Drop Foreign Keys dynamically to prevent dependency issues
    DECLARE @DropFkSql NVARCHAR(MAX) = N'';
    SELECT @DropFkSql += N'ALTER TABLE ' + QUOTENAME(OBJECT_NAME(parent_object_id)) + 
                         N' DROP CONSTRAINT ' + QUOTENAME(name) + N';' + CHAR(13)
    FROM sys.foreign_keys;

    IF (LEN(@DropFkSql) > 0)
    BEGIN
        EXEC sp_executesql @DropFkSql;
    END

    -- Drop Tables in reverse dependency order
    DROP TABLE IF EXISTS [TestCaseValidationRules];
    DROP TABLE IF EXISTS [TestCases];
    DROP TABLE IF EXISTS [TestSuites];
    DROP TABLE IF EXISTS [SoapExecutionGroupsPermissions];
    DROP TABLE IF EXISTS [SoapRequestFilePermissions];
    DROP TABLE IF EXISTS [SoapAppPermissions];
    DROP TABLE IF EXISTS [SoapNamespaces];
    DROP TABLE IF EXISTS [SoapOperationSchemas];
    DROP TABLE IF EXISTS [SoapWsdlHistory];
    DROP TABLE IF EXISTS [SoapResponseFileHistory];
    DROP TABLE IF EXISTS [SoapResponseEmbeddings];
    DROP TABLE IF EXISTS [SoapResponseFiles];
    DROP TABLE IF EXISTS [SoapExecutionItemRuns];
    DROP TABLE IF EXISTS [SoapExecutionRuns];
    DROP TABLE IF EXISTS [SoapExecutionGroupItems];
    DROP TABLE IF EXISTS [SoapExecutionGroups];
    DROP TABLE IF EXISTS [SoapRequestFileHistory];
    DROP TABLE IF EXISTS [SoapRequestFiles];
    DROP TABLE IF EXISTS [SoapOperations];
    DROP TABLE IF EXISTS [SoapWsdlSync];
    DROP TABLE IF EXISTS [SoapAppAuthentication];
    DROP TABLE IF EXISTS [SoapApplications];
    DROP TABLE IF EXISTS [UserSettings];
    DROP TABLE IF EXISTS [ConstantSettings];
    DROP TABLE IF EXISTS [EntityChangeHistory];
    DROP TABLE IF EXISTS [UserActivities];
    DROP TABLE IF EXISTS [Users];
END
GO

-- ==========================================
-- Create Users Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM [sys].[tables] 
    WHERE [name] = N'Users'
)
BEGIN
    CREATE TABLE [Users] (
        [UserId] NVARCHAR(20) PRIMARY KEY,   -- Windows login (Domain\Username)
        [Email] NVARCHAR(250) NOT NULL,
        [Department] NVARCHAR(100) NULL,
        [FirstName] NVARCHAR(100) NULL,
        [LastName] NVARCHAR(100) NULL,
        [Role] NVARCHAR(50) CHECK ([Role] IN (
            'Developer', 'Test Engineer', 'Requirement Engineer',
            'Team Leader', 'Project Manager', 'Business'
        )),
        [IsActive] BIT NOT NULL DEFAULT 1,
        [CreatedBy] NVARCHAR(20) NOT NULL,
        [CreatedDate] DATETIME NOT NULL DEFAULT GETDATE(),
        [LastUpdatedAt] DATETIME NULL,
        [LastUpdatedBy] NVARCHAR(20) NULL FOREIGN KEY REFERENCES [Users]([UserId])
    );
END
GO

-- ==========================================
-- Create UserActivities Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM [sys].[tables] 
    WHERE [name] = N'UserActivities'
)
BEGIN
    CREATE TABLE [UserActivities] (
        [Id] BIGINT IDENTITY(1,1) PRIMARY KEY,
        [UserId] NVARCHAR(20) NOT NULL,
        [FeatureName] NVARCHAR(100) NOT NULL,
        [TableName] NVARCHAR(100) NULL,      -- Target entity table name
        [TableId] NVARCHAR(100) NULL,        -- Target entity unique identifier/key
        [FeatureActivities] NVARCHAR(MAX) NULL,
        [Timestamp] DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [FK_UserActivities_Users] FOREIGN KEY ([UserId])
            REFERENCES [Users]([UserId]) ON DELETE CASCADE
    );
END
GO

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_UserActivities_UserId' AND [object_id] = OBJECT_ID(N'[UserActivities]'))
BEGIN
    CREATE INDEX [IX_UserActivities_UserId] ON [UserActivities]([UserId]);
END
GO

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_UserActivities_Timestamp' AND [object_id] = OBJECT_ID(N'[UserActivities]'))
BEGIN
    CREATE INDEX [IX_UserActivities_Timestamp] ON [UserActivities]([Timestamp]);
END
GO

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_UserActivities_TableName_TableId' AND [object_id] = OBJECT_ID(N'[UserActivities]'))
BEGIN
    CREATE INDEX [IX_UserActivities_TableName_TableId] ON [UserActivities]([TableName], [TableId]);
END
GO

-- ==========================================
-- Create EntityChangeHistory Table (Universal Audit Trail)
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM [sys].[tables] 
    WHERE [name] = N'EntityChangeHistory'
)
BEGIN
    CREATE TABLE [EntityChangeHistory] (
        [Id] BIGINT IDENTITY(1,1) PRIMARY KEY,
        [TableName] NVARCHAR(100) NOT NULL,    -- Target Table
        [TableId] NVARCHAR(100) NOT NULL,      -- Target Primary Key
        [ActionType] VARCHAR(20) NOT NULL CHECK ([ActionType] IN ('CREATE', 'UPDATE', 'DELETE')),
        [OldValuesJson] NVARCHAR(MAX) NULL,    -- Delta/JSON snapshot before change
        [NewValuesJson] NVARCHAR(MAX) NULL,    -- Delta/JSON snapshot after change
        [ChangeSummary] NVARCHAR(MAX) NULL,    -- Human readable summary of changes
        [ChangedAt] DATETIME NOT NULL DEFAULT GETDATE(),
        [ChangedBy] NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES [Users]([UserId])
    );
END
GO

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_EntityChangeHistory_Table' AND [object_id] = OBJECT_ID(N'[EntityChangeHistory]'))
BEGIN
    CREATE INDEX [IX_EntityChangeHistory_Table] ON [EntityChangeHistory]([TableName], [TableId]);
END
GO

-- ==========================================
-- Create ConstantSettings Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM [sys].[tables] 
    WHERE [name] = N'ConstantSettings'
)
BEGIN
    CREATE TABLE [ConstantSettings] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [Category] NVARCHAR(50) NOT NULL DEFAULT 'General', -- e.g., 'System', 'Theme', 'Grid', 'Layout', 'QuickLinks'
        [SettingKey] NVARCHAR(100) NOT NULL UNIQUE,              -- e.g., 'GridPageSize', 'PrimaryColor', 'SidebarWidth', 'RecentActivityLinks'
        [SettingValue] NVARCHAR(MAX) NOT NULL,            -- Scalar values ('25', '#007ACC', '250px') or JSON payloads
        [Description] NVARCHAR(500) NULL,
        [DataType] VARCHAR(20) NOT NULL DEFAULT 'String' 
            CHECK ([DataType] IN ('String', 'Number', 'Boolean', 'Json')),
        [IsUserOverridable] BIT NOT NULL DEFAULT 0, -- 1 = User can override; 0 = Global Read-Only
        [IsActive] BIT NOT NULL DEFAULT 1,
        [LastUpdatedAt] DATETIME NULL,
        [LastUpdatedBy] NVARCHAR(20) NULL FOREIGN KEY REFERENCES [Users]([UserId])
    );
END
GO

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_ConstantSettings_IsActive' AND [object_id] = OBJECT_ID(N'[ConstantSettings]'))
BEGIN
    CREATE INDEX [IX_ConstantSettings_IsActive] ON [ConstantSettings]([IsActive]);
END
GO

-- Seed RequestFileDiffCount Setting
IF NOT EXISTS (SELECT 1 FROM [ConstantSettings] WHERE [SettingKey] = 'RequestFileDiffCount')
BEGIN
    INSERT INTO [ConstantSettings] ([SettingKey], [SettingValue], [Description], [IsActive])
    VALUES ('RequestFileDiffCount', '5', 'Number of diff payload increments retained in history before forcing full base file snapshot', 1);
END
GO

-- ==========================================
-- Create UserSettings Table (Unified System & UI Preferences)
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM [sys].[tables] 
    WHERE [name] = N'UserSettings'
)
BEGIN
    CREATE TABLE [UserSettings] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [ConstantSettingId] INT NULL FOREIGN KEY REFERENCES [ConstantSettings]([Id]) ON DELETE SET NULL,
        [UserId] NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES [Users]([UserId]) ON DELETE CASCADE,
        [SettingValue] NVARCHAR(MAX) NOT NULL,
        [LastUpdatedAt] DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [UQ_UserSettings_User_Category_Key] UNIQUE ([UserId], [Category], [SettingKey])
    );
END
GO

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_UserSettings_UserId_Category' AND [object_id] = OBJECT_ID(N'[UserSettings]'))
BEGIN
    CREATE INDEX [IX_UserSettings_UserId_Category] ON [UserSettings]([UserId], [Category]);
END
GO

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_UserSettings_SettingKey' AND [object_id] = OBJECT_ID(N'[UserSettings]'))
BEGIN
    CREATE INDEX [IX_UserSettings_SettingKey] ON [UserSettings]([SettingKey]);
END
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ==========================================
-- 1. Create SoapApplications Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM sys.tables 
    WHERE name = N'SoapApplications' AND schema_id = SCHEMA_ID(N'dbo')
)
BEGIN
    CREATE TABLE dbo.SoapApplications (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [AppName] NVARCHAR(200) NOT NULL,
        [BaseUrl] NVARCHAR(500) NOT NULL,
        [WsdlRelativeUrl] NVARCHAR(250) NULL,
        [HealthcheckRelativeUrl] NVARCHAR(250) NULL,
        [Description] NVARCHAR(MAX) NULL,
        [IsActive] BIT NOT NULL CONSTRAINT DF_SoapApplications_IsActive DEFAULT 1,
        [Version] VARCHAR(50) NOT NULL,
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_SoapApplications_CreatedAt DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL,
        [LastUpdatedAt] DATETIME NULL,
        [LastUpdatedBy] NVARCHAR(20) NULL,
        
        CONSTRAINT PK_SoapApplications PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT UIX_SoapApplications_AppName UNIQUE ([AppName] ASC),
        CONSTRAINT FK_SoapApplications_CreatedBy_Users FOREIGN KEY ([CreatedBy]) REFERENCES dbo.Users([UserId]),
        CONSTRAINT FK_SoapApplications_LastUpdatedBy_Users FOREIGN KEY ([LastUpdatedBy]) REFERENCES dbo.Users([UserId])
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapApplications_AppName' AND object_id = OBJECT_ID(N'dbo.SoapApplications'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapApplications_AppName ON dbo.SoapApplications([AppName] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapApplications_IsActive' AND object_id = OBJECT_ID(N'dbo.SoapApplications'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapApplications_IsActive ON dbo.SoapApplications([IsActive] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapApplications_CreatedBy' AND object_id = OBJECT_ID(N'dbo.SoapApplications'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapApplications_CreatedBy ON dbo.SoapApplications([CreatedBy] ASC);
END
GO

-- ==========================================
-- 2. Create SoapAppAuthentication Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM sys.tables 
    WHERE name = N'SoapAppAuthentication' AND schema_id = SCHEMA_ID(N'dbo')
)
BEGIN
    CREATE TABLE dbo.SoapAppAuthentication (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [AppId] INT NOT NULL,
        [AuthenticationType] VARCHAR(50) NOT NULL,
        [EncryptedCredentialsJson] NVARCHAR(MAX) NOT NULL,
        [IsActive] BIT NOT NULL CONSTRAINT DF_SoapAppAuthentication_IsActive DEFAULT 1,
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_SoapAppAuthentication_CreatedAt DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL,
        [LastUpdatedAt] DATETIME NULL,
        [LastUpdatedBy] NVARCHAR(20) NULL,

        CONSTRAINT PK_SoapAppAuthentication PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT CK_SoapAppAuthentication_Type CHECK ([AuthenticationType] IN ('Basic', 'NTLM', 'APIKey', 'OAuth2')),
        CONSTRAINT FK_SoapAppAuthentication_SoapApplications FOREIGN KEY ([AppId]) REFERENCES dbo.SoapApplications([Id]) ON DELETE CASCADE,
        CONSTRAINT FK_SoapAppAuthentication_CreatedBy_Users FOREIGN KEY ([CreatedBy]) REFERENCES dbo.Users([UserId]),
        CONSTRAINT FK_SoapAppAuthentication_LastUpdatedBy_Users FOREIGN KEY ([LastUpdatedBy]) REFERENCES dbo.Users([UserId])
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapAppAuthentication_AppId' AND object_id = OBJECT_ID(N'dbo.SoapAppAuthentication'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapAppAuthentication_AppId ON dbo.SoapAppAuthentication([AppId] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapAppAuthentication_IsActive' AND object_id = OBJECT_ID(N'dbo.SoapAppAuthentication'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapAppAuthentication_IsActive ON dbo.SoapAppAuthentication([IsActive] ASC);
END
GO

-- ==========================================
-- 3. Create SoapWsdlSync Table (Moved Up to Solve Dependency Error)
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM sys.tables 
    WHERE name = N'SoapWsdlSync' AND schema_id = SCHEMA_ID(N'dbo')
)
BEGIN
    CREATE TABLE dbo.SoapWsdlSync (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [AppId] INT NOT NULL,
        [WsdlUrl] NVARCHAR(500) NULL,
        [WsdlContent] NVARCHAR(MAX) NOT NULL,
        [Version] VARCHAR(50) NOT NULL,
        [FileHash] VARCHAR(64) NULL,
        [SyncedAt] DATETIME NOT NULL CONSTRAINT DF_SoapWsdlSync_SyncedAt DEFAULT GETDATE(),
        [SyncedBy] NVARCHAR(20) NOT NULL,

        CONSTRAINT PK_SoapWsdlSync PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT FK_SoapWsdlSync_SoapApplications FOREIGN KEY ([AppId]) REFERENCES dbo.SoapApplications([Id]) ON DELETE CASCADE,
        CONSTRAINT FK_SoapWsdlSync_SyncedBy_Users FOREIGN KEY ([SyncedBy]) REFERENCES dbo.Users([UserId])
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapWsdlSync_AppId' AND object_id = OBJECT_ID(N'dbo.SoapWsdlSync'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapWsdlSync_AppId ON dbo.SoapWsdlSync([AppId] ASC);
END
GO

-- ==========================================
-- 4. Create SoapOperations Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM sys.tables 
    WHERE name = N'SoapOperations' AND schema_id = SCHEMA_ID(N'dbo')
)
BEGIN
    CREATE TABLE dbo.SoapOperations (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [AppId] INT NOT NULL,
        [WsdlSyncId] INT NOT NULL,
        [OperationName] NVARCHAR(200) NOT NULL,
        [Description] NVARCHAR(MAX) NULL,
        [SoapAction] NVARCHAR(200) NULL,
        [InputRootElementName] NVARCHAR(200) NULL,
        [OutputRootElementName] NVARCHAR(200) NULL,
        [IsActive] BIT NOT NULL CONSTRAINT DF_SoapOperations_IsActive DEFAULT 1,
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_SoapOperations_CreatedAt DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL,
        [LastUpdatedAt] DATETIME NULL,
        [LastUpdatedBy] NVARCHAR(20) NULL,

        CONSTRAINT PK_SoapOperations PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT UIX_SoapOperations_WsdlSyncId_OpName UNIQUE ([WsdlSyncId] ASC, [OperationName] ASC),
        CONSTRAINT FK_SoapOperations_SoapApplications FOREIGN KEY ([AppId]) REFERENCES dbo.SoapApplications([Id]),
        CONSTRAINT FK_SoapOperations_SoapWsdlSync FOREIGN KEY ([WsdlSyncId]) REFERENCES dbo.SoapWsdlSync([Id]) ON DELETE CASCADE,
        CONSTRAINT FK_SoapOperations_CreatedBy_Users FOREIGN KEY ([CreatedBy]) REFERENCES dbo.Users([UserId]),
        CONSTRAINT FK_SoapOperations_LastUpdatedBy_Users FOREIGN KEY ([LastUpdatedBy]) REFERENCES dbo.Users([UserId])
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapOperations_AppId' AND object_id = OBJECT_ID(N'dbo.SoapOperations'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapOperations_AppId ON dbo.SoapOperations([AppId] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapOperations_WsdlSyncId' AND object_id = OBJECT_ID(N'dbo.SoapOperations'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapOperations_WsdlSyncId ON dbo.SoapOperations([WsdlSyncId] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapOperations_IsActive' AND object_id = OBJECT_ID(N'dbo.SoapOperations'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapOperations_IsActive ON dbo.SoapOperations([IsActive] ASC);
END
GO

-- ==========================================
-- 5. Create SoapRequestFiles Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM sys.tables 
    WHERE name = N'SoapRequestFiles' AND schema_id = SCHEMA_ID(N'dbo')
)
BEGIN
    CREATE TABLE dbo.SoapRequestFiles (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [OperationId] INT NOT NULL,
        [FileName] NVARCHAR(250) NOT NULL,
        [FileData] VARBINARY(MAX) NOT NULL,
        [UncompressedSizeBytes] INT NULL,
        [FileHash] VARCHAR(64) NULL,
        [Version] VARCHAR(50) NOT NULL,
        [IsActive] BIT NOT NULL CONSTRAINT DF_SoapRequestFiles_IsActive DEFAULT 1,
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_SoapRequestFiles_CreatedAt DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL,
        [LastUpdatedAt] DATETIME NULL,
        [LastUpdatedBy] NVARCHAR(20) NULL,

        CONSTRAINT PK_SoapRequestFiles PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT FK_SoapRequestFiles_SoapOperations FOREIGN KEY ([OperationId]) REFERENCES dbo.SoapOperations([Id]) ON DELETE CASCADE,
        CONSTRAINT FK_SoapRequestFiles_CreatedBy_Users FOREIGN KEY ([CreatedBy]) REFERENCES dbo.Users([UserId]),
        CONSTRAINT FK_SoapRequestFiles_LastUpdatedBy_Users FOREIGN KEY ([LastUpdatedBy]) REFERENCES dbo.Users([UserId])
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapRequestFiles_OperationId' AND object_id = OBJECT_ID(N'dbo.SoapRequestFiles'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapRequestFiles_OperationId ON dbo.SoapRequestFiles([OperationId] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapRequestFiles_CreatedBy' AND object_id = OBJECT_ID(N'dbo.SoapRequestFiles'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapRequestFiles_CreatedBy ON dbo.SoapRequestFiles([CreatedBy] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapRequestFiles_IsActive' AND object_id = OBJECT_ID(N'dbo.SoapRequestFiles'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapRequestFiles_IsActive ON dbo.SoapRequestFiles([IsActive] ASC);
END
GO

-- ==========================================
-- 6. Create SoapRequestFileHistory Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM sys.tables 
    WHERE name = N'SoapRequestFileHistory' AND schema_id = SCHEMA_ID(N'dbo')
)
BEGIN
    CREATE TABLE dbo.SoapRequestFileHistory (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [RequestFileId] INT NOT NULL,
        [Version] VARCHAR(50) NOT NULL,
        [FileData] VARBINARY(MAX) NULL,
        [DiffData] VARBINARY(MAX) NULL,
        [UncompressedSizeBytes] INT NULL,
        [FileHash] VARCHAR(64) NULL,
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_SoapRequestFileHistory_CreatedAt DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL,

        CONSTRAINT PK_SoapRequestFileHistory PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT FK_SoapRequestFileHistory_SoapRequestFiles FOREIGN KEY ([RequestFileId]) REFERENCES dbo.SoapRequestFiles([Id]) ON DELETE CASCADE,
        CONSTRAINT FK_SoapRequestFileHistory_CreatedBy_Users FOREIGN KEY ([CreatedBy]) REFERENCES dbo.Users([UserId])
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapRequestFileHistory_RequestFileId' AND object_id = OBJECT_ID(N'dbo.SoapRequestFileHistory'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapRequestFileHistory_RequestFileId ON dbo.SoapRequestFileHistory([RequestFileId] ASC);
END
GO

-- ==========================================
-- 7. Create SoapExecutionGroups Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM sys.tables 
    WHERE name = N'SoapExecutionGroups' AND schema_id = SCHEMA_ID(N'dbo')
)
BEGIN
    CREATE TABLE dbo.SoapExecutionGroups (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [AppId] INT NULL,
        [GroupName] NVARCHAR(200) NOT NULL,
        [Description] NVARCHAR(MAX) NULL,
        [IsActive] BIT NOT NULL CONSTRAINT DF_SoapExecutionGroups_IsActive DEFAULT 1,
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_SoapExecutionGroups_CreatedAt DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL,
        [LastUpdatedAt] DATETIME NULL,
        [LastUpdatedBy] NVARCHAR(20) NULL,

        CONSTRAINT PK_SoapExecutionGroups PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT FK_SoapExecutionGroups_SoapApplications FOREIGN KEY ([AppId]) REFERENCES dbo.SoapApplications([Id]) ON DELETE SET NULL,
        CONSTRAINT FK_SoapExecutionGroups_CreatedBy_Users FOREIGN KEY ([CreatedBy]) REFERENCES dbo.Users([UserId]),
        CONSTRAINT FK_SoapExecutionGroups_LastUpdatedBy_Users FOREIGN KEY ([LastUpdatedBy]) REFERENCES dbo.Users([UserId])
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapExecutionGroups_AppId' AND object_id = OBJECT_ID(N'dbo.SoapExecutionGroups'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapExecutionGroups_AppId ON dbo.SoapExecutionGroups([AppId] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapExecutionGroups_IsActive' AND object_id = OBJECT_ID(N'dbo.SoapExecutionGroups'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapExecutionGroups_IsActive ON dbo.SoapExecutionGroups([IsActive] ASC);
END
GO

-- ==========================================
-- 8. Create SoapExecutionGroupItems Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM sys.tables 
    WHERE name = N'SoapExecutionGroupItems' AND schema_id = SCHEMA_ID(N'dbo')
)
BEGIN
    CREATE TABLE dbo.SoapExecutionGroupItems (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [ExecutionGroupId] INT NOT NULL,
        [RequestFileId] INT NOT NULL,
        [RequestFileHistoryId] INT NULL,
        [ExecutionOrder] INT NOT NULL CONSTRAINT DF_SoapExecutionGroupItems_ExecutionOrder DEFAULT 1,
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_SoapExecutionGroupItems_CreatedAt DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL,

        CONSTRAINT PK_SoapExecutionGroupItems PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT FK_SoapExecutionGroupItems_SoapExecutionGroups FOREIGN KEY ([ExecutionGroupId]) REFERENCES dbo.SoapExecutionGroups([Id]) ON DELETE CASCADE,
        CONSTRAINT FK_SoapExecutionGroupItems_SoapRequestFiles FOREIGN KEY ([RequestFileId]) REFERENCES dbo.SoapRequestFiles([Id]),
        CONSTRAINT FK_SoapExecutionGroupItems_SoapRequestFileHistory FOREIGN KEY ([RequestFileHistoryId]) REFERENCES dbo.SoapRequestFileHistory([Id]),
        CONSTRAINT FK_SoapExecutionGroupItems_CreatedBy_Users FOREIGN KEY ([CreatedBy]) REFERENCES dbo.Users([UserId])
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapExecutionGroupItems_GroupId' AND object_id = OBJECT_ID(N'dbo.SoapExecutionGroupItems'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapExecutionGroupItems_GroupId ON dbo.SoapExecutionGroupItems([ExecutionGroupId] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapExecutionGroupItems_HistoryId' AND object_id = OBJECT_ID(N'dbo.SoapExecutionGroupItems'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapExecutionGroupItems_HistoryId ON dbo.SoapExecutionGroupItems([RequestFileHistoryId] ASC);
END
GO

-- ==========================================
-- 9. Create SoapExecutionRuns Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM sys.tables 
    WHERE name = N'SoapExecutionRuns' AND schema_id = SCHEMA_ID(N'dbo')
)
BEGIN
    CREATE TABLE dbo.SoapExecutionRuns (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [ExecutionGroupId] INT NOT NULL,
        [RunStatus] VARCHAR(20) NOT NULL CONSTRAINT DF_SoapExecutionRuns_RunStatus DEFAULT 'Pending',
        [ExecutedBy] NVARCHAR(20) NOT NULL,
        [StartedAt] DATETIME NOT NULL CONSTRAINT DF_SoapExecutionRuns_StartedAt DEFAULT GETDATE(),
        [CompletedAt] DATETIME NULL,

        CONSTRAINT PK_SoapExecutionRuns PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT CK_SoapExecutionRuns_RunStatus CHECK ([RunStatus] IN ('Pending', 'InProgress', 'Completed', 'Failed', 'Cancelled')),
        CONSTRAINT FK_SoapExecutionRuns_SoapExecutionGroups FOREIGN KEY ([ExecutionGroupId]) REFERENCES dbo.SoapExecutionGroups([Id]) ON DELETE CASCADE,
        CONSTRAINT FK_SoapExecutionRuns_ExecutedBy_Users FOREIGN KEY ([ExecutedBy]) REFERENCES dbo.Users([UserId])
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapExecutionRuns_GroupId' AND object_id = OBJECT_ID(N'dbo.SoapExecutionRuns'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapExecutionRuns_GroupId ON dbo.SoapExecutionRuns([ExecutionGroupId] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapExecutionRuns_RunStatus' AND object_id = OBJECT_ID(N'dbo.SoapExecutionRuns'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapExecutionRuns_RunStatus ON dbo.SoapExecutionRuns([RunStatus] ASC);
END
GO

-- ==========================================
-- 10. Create SoapExecutionItemRuns Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM sys.tables 
    WHERE name = N'SoapExecutionItemRuns' AND schema_id = SCHEMA_ID(N'dbo')
)
BEGIN
    CREATE TABLE dbo.SoapExecutionItemRuns (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [ExecutionRunId] INT NOT NULL,
        [ExecutionGroupItemId] INT NOT NULL,
        [ItemExecutionStatus] VARCHAR(20) NOT NULL CONSTRAINT DF_SoapExecutionItemRuns_Status DEFAULT 'Pending',
        [ExecutedAt] DATETIME NOT NULL CONSTRAINT DF_SoapExecutionItemRuns_ExecutedAt DEFAULT GETDATE(),
        [ExecutedBy] NVARCHAR(20) NOT NULL,
        [HttpStatusCode] INT NULL,
        [ExecutionTimeMs] INT NULL,

        CONSTRAINT PK_SoapExecutionItemRuns PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT CK_SoapExecutionItemRuns_Status CHECK ([ItemExecutionStatus] IN ('Pending', 'InProgress', 'Success', 'Failure', 'Skipped')),
        CONSTRAINT FK_SoapExecutionItemRuns_SoapExecutionRuns FOREIGN KEY ([ExecutionRunId]) REFERENCES dbo.SoapExecutionRuns([Id]) ON DELETE CASCADE,
        CONSTRAINT FK_SoapExecutionItemRuns_SoapExecutionGroupItems FOREIGN KEY ([ExecutionGroupItemId]) REFERENCES dbo.SoapExecutionGroupItems([Id]),
        CONSTRAINT FK_SoapExecutionItemRuns_ExecutedBy_Users FOREIGN KEY ([ExecutedBy]) REFERENCES dbo.Users([UserId])
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapExecutionItemRuns_RunId' AND object_id = OBJECT_ID(N'dbo.SoapExecutionItemRuns'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapExecutionItemRuns_RunId ON dbo.SoapExecutionItemRuns([ExecutionRunId] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapExecutionItemRuns_GroupItemId' AND object_id = OBJECT_ID(N'dbo.SoapExecutionItemRuns'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapExecutionItemRuns_GroupItemId ON dbo.SoapExecutionItemRuns([ExecutionGroupItemId] ASC);
END
GO

-- ==========================================
-- 11. Create SoapResponseFiles Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM sys.tables 
    WHERE name = N'SoapResponseFiles' AND schema_id = SCHEMA_ID(N'dbo')
)
BEGIN
    CREATE TABLE dbo.SoapResponseFiles (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [ExecutionItemRunId] INT NOT NULL,
        [ResponseFormat] VARCHAR(10) NULL,
        [FileData] VARBINARY(MAX) NOT NULL,
        [UncompressedSizeBytes] INT NULL,
        [FileHash] VARCHAR(64) NULL,
        [Version] VARCHAR(50) NOT NULL,
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_SoapResponseFiles_CreatedAt DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL,

        CONSTRAINT PK_SoapResponseFiles PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT CK_SoapResponseFiles_Format CHECK ([ResponseFormat] IS NULL OR [ResponseFormat] IN ('XML','JSON','PDF','BINARY')),
        CONSTRAINT FK_SoapResponseFiles_SoapExecutionItemRuns FOREIGN KEY ([ExecutionItemRunId]) REFERENCES dbo.SoapExecutionItemRuns([Id]) ON DELETE CASCADE,
        CONSTRAINT FK_SoapResponseFiles_CreatedBy_Users FOREIGN KEY ([CreatedBy]) REFERENCES dbo.Users([UserId])
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapResponseFiles_ExecutionItemRunId' AND object_id = OBJECT_ID(N'dbo.SoapResponseFiles'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapResponseFiles_ExecutionItemRunId ON dbo.SoapResponseFiles([ExecutionItemRunId] ASC);
END
GO

-- ==========================================
-- 12. Create SoapResponseEmbeddings Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM sys.tables 
    WHERE name = N'SoapResponseEmbeddings' AND schema_id = SCHEMA_ID(N'dbo')
)
BEGIN
    CREATE TABLE dbo.SoapResponseEmbeddings (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [ResponseFileId] INT NOT NULL,
        [AttachmentName] NVARCHAR(250) NOT NULL,
        [ContentType] NVARCHAR(100) NOT NULL,
        [FileData] VARBINARY(MAX) NOT NULL,
        [UncompressedSizeBytes] INT NULL,
        [FileHash] VARCHAR(64) NULL,
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_SoapResponseEmbeddings_CreatedAt DEFAULT GETDATE(),

        CONSTRAINT PK_SoapResponseEmbeddings PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT FK_SoapResponseEmbeddings_SoapResponseFiles FOREIGN KEY ([ResponseFileId]) REFERENCES dbo.SoapResponseFiles([Id]) ON DELETE CASCADE
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapResponseEmbeddings_ResponseFileId' AND object_id = OBJECT_ID(N'dbo.SoapResponseEmbeddings'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapResponseEmbeddings_ResponseFileId ON dbo.SoapResponseEmbeddings([ResponseFileId] ASC);
END
GO

-- ==========================================
-- 13. Create SoapResponseFileHistory Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM sys.tables 
    WHERE name = N'SoapResponseFileHistory' AND schema_id = SCHEMA_ID(N'dbo')
)
BEGIN
    CREATE TABLE dbo.SoapResponseFileHistory (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [ResponseFileId] INT NOT NULL,
        [Version] VARCHAR(50) NOT NULL,
        [FileData] VARBINARY(MAX) NULL,
        [DiffData] VARBINARY(MAX) NULL,
        [UncompressedSizeBytes] INT NULL,
        [FileHash] VARCHAR(64) NULL,
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_SoapResponseFileHistory_CreatedAt DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL,

        CONSTRAINT PK_SoapResponseFileHistory PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT FK_SoapResponseFileHistory_SoapResponseFiles FOREIGN KEY ([ResponseFileId]) REFERENCES dbo.SoapResponseFiles([Id]) ON DELETE CASCADE,
        CONSTRAINT FK_SoapResponseFileHistory_CreatedBy_Users FOREIGN KEY ([CreatedBy]) REFERENCES dbo.Users([UserId])
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapResponseFileHistory_ResponseFileId' AND object_id = OBJECT_ID(N'dbo.SoapResponseFileHistory'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapResponseFileHistory_ResponseFileId ON dbo.SoapResponseFileHistory([ResponseFileId] ASC);
END
GO

-- ==========================================
-- 14. Create SoapWsdlHistory Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM sys.tables 
    WHERE name = N'SoapWsdlHistory' AND schema_id = SCHEMA_ID(N'dbo')
)
BEGIN
    CREATE TABLE dbo.SoapWsdlHistory (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [WsdlSyncId] INT NOT NULL,
        [Version] VARCHAR(50) NOT NULL,
        [WsdlContent] NVARCHAR(MAX) NULL,
        [DiffContent] NVARCHAR(MAX) NULL,
        [SystemLog] NVARCHAR(MAX) NOT NULL,
        [Comment] NVARCHAR(MAX) NULL,
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_SoapWsdlHistory_CreatedAt DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL,

        CONSTRAINT PK_SoapWsdlHistory PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT FK_SoapWsdlHistory_SoapWsdlSync FOREIGN KEY ([WsdlSyncId]) REFERENCES dbo.SoapWsdlSync([Id]) ON DELETE CASCADE,
        CONSTRAINT FK_SoapWsdlHistory_CreatedBy_Users FOREIGN KEY ([CreatedBy]) REFERENCES dbo.Users([UserId])
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapWsdlHistory_WsdlSyncId' AND object_id = OBJECT_ID(N'dbo.SoapWsdlHistory'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapWsdlHistory_WsdlSyncId ON dbo.SoapWsdlHistory([WsdlSyncId] ASC);
END
GO

-- ==========================================
-- 15. Create SoapOperationSchemas Table (Fixed Multi-Cascade Path)
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM sys.tables 
    WHERE name = N'SoapOperationSchemas' AND schema_id = SCHEMA_ID(N'dbo')
)
BEGIN
    CREATE TABLE dbo.SoapOperationSchemas (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [WsdlSyncId] INT NOT NULL,
        [OperationId] INT NULL,
        [TargetNamespace] NVARCHAR(500) NULL,
        [XsdContent] NVARCHAR(MAX) NOT NULL,
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_SoapOperationSchemas_CreatedAt DEFAULT GETDATE(),

        CONSTRAINT PK_SoapOperationSchemas PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT FK_SoapOperationSchemas_SoapWsdlSync FOREIGN KEY ([WsdlSyncId]) REFERENCES dbo.SoapWsdlSync([Id]) ON DELETE CASCADE,
        CONSTRAINT FK_SoapOperationSchemas_SoapOperations FOREIGN KEY ([OperationId]) REFERENCES dbo.SoapOperations([Id]) -- No CASCADE to avoid SQL Error 1785
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapOperationSchemas_WsdlSyncId' AND object_id = OBJECT_ID(N'dbo.SoapOperationSchemas'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapOperationSchemas_WsdlSyncId ON dbo.SoapOperationSchemas([WsdlSyncId] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapOperationSchemas_OperationId' AND object_id = OBJECT_ID(N'dbo.SoapOperationSchemas'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapOperationSchemas_OperationId ON dbo.SoapOperationSchemas([OperationId] ASC);
END
GO

-- ==========================================
-- 16. Create SoapNamespaces Table (Fixed Multi-Cascade Path)
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM sys.tables 
    WHERE name = N'SoapNamespaces' AND schema_id = SCHEMA_ID(N'dbo')
)
BEGIN
    CREATE TABLE dbo.SoapNamespaces (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [WsdlSyncId] INT NOT NULL,
        [OperationId] INT NULL,
        [Prefix] NVARCHAR(50) NOT NULL,
        [NamespaceUri] NVARCHAR(500) NOT NULL,
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_SoapNamespaces_CreatedAt DEFAULT GETDATE(),

        CONSTRAINT PK_SoapNamespaces PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT FK_SoapNamespaces_SoapWsdlSync FOREIGN KEY ([WsdlSyncId]) REFERENCES dbo.SoapWsdlSync([Id]) ON DELETE CASCADE,
        CONSTRAINT FK_SoapNamespaces_SoapOperations FOREIGN KEY ([OperationId]) REFERENCES dbo.SoapOperations([Id]) -- No CASCADE to avoid SQL Error 1785
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapNamespaces_WsdlSyncId' AND object_id = OBJECT_ID(N'dbo.SoapNamespaces'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapNamespaces_WsdlSyncId ON dbo.SoapNamespaces([WsdlSyncId] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapNamespaces_OperationId' AND object_id = OBJECT_ID(N'dbo.SoapNamespaces'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapNamespaces_OperationId ON dbo.SoapNamespaces([OperationId] ASC);
END
GO

-- ==========================================
-- Create SoapAppPermissions Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM sys.tables 
    WHERE name = N'SoapAppPermissions' AND schema_id = SCHEMA_ID(N'dbo')
)
BEGIN
    CREATE TABLE dbo.SoapAppPermissions (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [AppId] INT NOT NULL,
        [SharedWithUserId] NVARCHAR(20) NOT NULL,
        [AccessLevel] VARCHAR(20) NOT NULL CONSTRAINT DF_SoapAppPermissions_AccessLevel DEFAULT 'Read' CHECK ([AccessLevel] IN ('Read', 'Write')), -- Write includes Read
        [GrantedAt] DATETIME NOT NULL CONSTRAINT DF_SoapAppPermissions_GrantedAt DEFAULT GETDATE(),
        [GrantedBy] NVARCHAR(20) NOT NULL,

        CONSTRAINT PK_SoapAppPermissions PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT FK_SoapAppPermissions_SoapApplications FOREIGN KEY ([AppId]) REFERENCES dbo.SoapApplications([Id]) ON DELETE CASCADE,
        CONSTRAINT FK_SoapAppPermissions_SharedWithUserId_Users FOREIGN KEY ([SharedWithUserId]) REFERENCES dbo.Users([UserId]),
        CONSTRAINT FK_SoapAppPermissions_GrantedBy_Users FOREIGN KEY ([GrantedBy]) REFERENCES dbo.Users([UserId]),
        CONSTRAINT UQ_SoapAppPermissions UNIQUE ([AppId], [SharedWithUserId])
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapAppPermissions_AppId' AND object_id = OBJECT_ID(N'dbo.SoapAppPermissions'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapAppPermissions_AppId ON dbo.SoapAppPermissions([AppId] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapAppPermissions_SharedWithUserId' AND object_id = OBJECT_ID(N'dbo.SoapAppPermissions'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapAppPermissions_SharedWithUserId ON dbo.SoapAppPermissions([SharedWithUserId] ASC);
END
GO

-- ==========================================
-- Create SoapRequestFilePermissions Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM sys.tables 
    WHERE name = N'SoapRequestFilePermissions' AND schema_id = SCHEMA_ID(N'dbo')
)
BEGIN
    CREATE TABLE [SoapRequestFilePermissions] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [RequestFileId] INT NOT NULL FOREIGN KEY REFERENCES [SoapRequestFiles]([Id]) ON DELETE CASCADE,
        [SharedWithUserId] NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES [Users]([UserId]),
        [AccessLevel] VARCHAR(20) NOT NULL DEFAULT 'Read' CHECK ([AccessLevel] IN ('Read', 'Execute', 'Write')), -- Write > Execute > Read
        [GrantedAt] DATETIME NOT NULL DEFAULT GETDATE(),
        [GrantedBy] NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES [Users]([UserId]),
        CONSTRAINT [UQ_SoapRequestFilePermissions] UNIQUE ([RequestFileId], [SharedWithUserId])
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapRequestFilePermissions_RequestFileId' AND object_id = OBJECT_ID(N'dbo.SoapRequestFilePermissions'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapRequestFilePermissions_RequestFileId ON dbo.SoapRequestFilePermissions([RequestFileId] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapRequestFilePermissions_SharedWithUserId' AND object_id = OBJECT_ID(N'dbo.SoapRequestFilePermissions'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapRequestFilePermissions_SharedWithUserId ON dbo.SoapRequestFilePermissions([SharedWithUserId] ASC);
END
GO

-- ==========================================
-- Create SoapExecutionGroupsPermissions Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM [sys].[tables] 
    WHERE [name] = N'SoapExecutionGroupsPermissions'
)
BEGIN
    CREATE TABLE [SoapExecutionGroupsPermissions] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [ExecutionGroupId] INT NOT NULL FOREIGN KEY REFERENCES [SoapExecutionGroups]([Id]) ON DELETE CASCADE,
        [SharedWithUserId] NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES [Users]([UserId]),
        [AccessLevel] VARCHAR(20) NOT NULL DEFAULT 'Read' CHECK ([AccessLevel] IN ('Read', 'Execute', 'Write')), -- Write > Execute > Read
        [GrantedAt] DATETIME NOT NULL DEFAULT GETDATE(),
        [GrantedBy] NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES [Users]([UserId]),
        CONSTRAINT [UQ_SoapExecutionGroupsPermissions] UNIQUE ([ExecutionGroupId], [SharedWithUserId])
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapExecutionGroupsPermissions_GroupId' AND object_id = OBJECT_ID(N'dbo.SoapExecutionGroupsPermissions'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapExecutionGroupsPermissions_GroupId ON dbo.SoapExecutionGroupsPermissions([ExecutionGroupId] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapExecutionGroupsPermissions_SharedWithUserId' AND object_id = OBJECT_ID(N'dbo.SoapExecutionGroupsPermissions'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapExecutionGroupsPermissions_SharedWithUserId ON dbo.SoapExecutionGroupsPermissions([SharedWithUserId] ASC);
END
GO

-- ==========================================
-- Create TestSuites Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM [sys].[tables] 
    WHERE [name] = N'TestSuites'
)
BEGIN
    CREATE TABLE [TestSuites] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [SuiteName] NVARCHAR(200) NOT NULL,
        [Description] NVARCHAR(MAX) NULL,
        [IsActive] BIT NOT NULL DEFAULT 1,
        [CreatedAt] DATETIME NOT NULL DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES [Users]([UserId])
    );
END
GO

-- ==========================================
-- Create TestCases Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM [sys].[tables] 
    WHERE [name] = N'TestCases'
)
BEGIN
    CREATE TABLE [TestCases] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [TestSuiteId] INT NOT NULL FOREIGN KEY REFERENCES [TestSuites]([Id]) ON DELETE CASCADE,
        [RequestFileId] INT NOT NULL FOREIGN KEY REFERENCES [SoapRequestFiles]([Id]),
        [TestCaseName] NVARCHAR(200) NOT NULL,
        [Description] NVARCHAR(MAX) NULL,
        [ExpectedResponseFormat] VARCHAR(10) CHECK ([ExpectedResponseFormat] IN ('XML','JSON','PDF')),
        [CreatedAt] DATETIME NOT NULL DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES [Users]([UserId])
    );
END
GO

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_TestCases_TestSuiteId' AND [object_id] = OBJECT_ID(N'[TestCases]'))
BEGIN
    CREATE INDEX [IX_TestCases_TestSuiteId] ON [TestCases]([TestSuiteId]);
END
GO

-- ==========================================
-- Create TestCaseValidationRules Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM [sys].[tables] 
    WHERE [name] = N'TestCaseValidationRules'
)
BEGIN
    CREATE TABLE [TestCaseValidationRules] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [TestCaseId] INT NOT NULL FOREIGN KEY REFERENCES [TestCases]([Id]) ON DELETE CASCADE,
        [RuleType] NVARCHAR(50) NOT NULL,
        [TargetExpression] NVARCHAR(MAX) NOT NULL,
        [ExpectedValue] NVARCHAR(MAX) NOT NULL,
        [IsActive] BIT NOT NULL DEFAULT 1
    );
END
GO

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_TestCaseValidationRules_TestCaseId' AND [object_id] = OBJECT_ID(N'[TestCaseValidationRules]'))
BEGIN
    CREATE INDEX [IX_TestCaseValidationRules_TestCaseId] ON [TestCaseValidationRules]([TestCaseId]);
END
GO