-- ==========================================
-- Configuration & Initialization
-- ==========================================
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
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Users')
BEGIN
    -- Drop Foreign Keys dynamically to prevent dependency locking
    DECLARE @DropFkSql NVARCHAR(MAX) = N'';
    SELECT @DropFkSql += N'ALTER TABLE ' + QUOTENAME(OBJECT_SCHEMA_NAME(parent_object_id)) + 
                         N'.' + QUOTENAME(OBJECT_NAME(parent_object_id)) + 
                         N' DROP CONSTRAINT ' + QUOTENAME(name) + N';' + CHAR(13)
    FROM sys.foreign_keys
    WHERE parent_object_id IN (
        SELECT object_id FROM sys.tables WHERE schema_id = SCHEMA_ID('dbo')
    );

    IF (LEN(@DropFkSql) > 0)
    BEGIN
        EXEC sp_executesql @DropFkSql;
    END

    -- Drop Tables in reverse dependency order
    DROP TABLE IF EXISTS dbo.[SoapNamespaces];
    DROP TABLE IF EXISTS dbo.[SoapOperationSchemas];
    DROP TABLE IF EXISTS dbo.[SoapResponseFileHistory];
    DROP TABLE IF EXISTS dbo.[SoapResponseEmbeddings];
    DROP TABLE IF EXISTS dbo.[SoapResponseFiles];
    DROP TABLE IF EXISTS dbo.[SoapExecutionItemRuns];
    DROP TABLE IF EXISTS dbo.[SoapExecutionRuns];
    DROP TABLE IF EXISTS dbo.[SoapExecutionGroupItems];
    DROP TABLE IF EXISTS dbo.[SoapExecutionGroups];
    DROP TABLE IF EXISTS dbo.[SoapRequestFileHistory];
    DROP TABLE IF EXISTS dbo.[SoapRequestFiles];
    DROP TABLE IF EXISTS dbo.[SoapOperations];
    DROP TABLE IF EXISTS dbo.[SoapWsdlSyncHistory];
    DROP TABLE IF EXISTS dbo.[SoapWsdlSync];
    DROP TABLE IF EXISTS dbo.[SoapApplications];
    DROP TABLE IF EXISTS dbo.[SoapAppAuthentication];
    DROP TABLE IF EXISTS dbo.[UserSettings];
    DROP TABLE IF EXISTS dbo.[ConstantSettings];
    DROP TABLE IF EXISTS dbo.[EntityChangeHistory];
    DROP TABLE IF EXISTS dbo.[UserActivities];
    DROP TABLE IF EXISTS dbo.[Users];
END
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ==========================================
-- 1. Create Users Table
-- ==========================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'Users' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[Users] (
        [UserId] NVARCHAR(20) NOT NULL,
        [Email] NVARCHAR(250) NOT NULL,
        [Department] NVARCHAR(100) NULL,
        [FirstName] NVARCHAR(100) NULL,
        [LastName] NVARCHAR(100) NULL,
        [Role] NVARCHAR(50) NULL,
        [IsActive] BIT NOT NULL CONSTRAINT DF_Users_IsActive DEFAULT 1,
        [CreatedBy] NVARCHAR(20) NOT NULL,
        [CreatedDate] DATETIME NOT NULL CONSTRAINT DF_Users_CreatedDate DEFAULT GETDATE(),
        [LastUpdatedAt] DATETIME NULL,
        [LastUpdatedBy] NVARCHAR(20) NULL,

        CONSTRAINT PK_Users PRIMARY KEY CLUSTERED ([UserId] ASC),
        CONSTRAINT CK_Users_Role CHECK ([Role] IS NULL OR [Role] IN (
            'Developer', 'Test Engineer', 'Requirement Engineer',
            'Team Leader', 'Project Manager', 'Business'
        ))
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Users_CreatedBy_Users')
BEGIN
    ALTER TABLE dbo.[Users] ADD CONSTRAINT FK_Users_CreatedBy_Users 
    FOREIGN KEY ([CreatedBy]) REFERENCES dbo.[Users]([UserId]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Users_LastUpdatedBy_Users')
BEGIN
    ALTER TABLE dbo.[Users] ADD CONSTRAINT FK_Users_LastUpdatedBy_Users 
    FOREIGN KEY ([LastUpdatedBy]) REFERENCES dbo.[Users]([UserId]);
END
GO

-- Extended Properties for Users
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'System user accounts and profiles.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Users';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Windows Domain\Username login identity.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Users', @level2type=N'COLUMN',@level2name=N'UserId';
GO

-- ==========================================
-- 2. Create UserActivities Table
-- ==========================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'UserActivities' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[UserActivities] (
        [Id] BIGINT IDENTITY(1,1) NOT NULL,
        [UserId] NVARCHAR(20) NOT NULL,
        [FeatureName] NVARCHAR(100) NOT NULL,
        [TableName] NVARCHAR(100) NULL,
        [TableId] NVARCHAR(100) NULL,
        [FeatureActivities] NVARCHAR(MAX) NULL,
        [Timestamp] DATETIME NOT NULL CONSTRAINT DF_UserActivities_Timestamp DEFAULT GETDATE(),

        CONSTRAINT PK_UserActivities PRIMARY KEY CLUSTERED ([Id] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_UserActivities_Users_UserId')
BEGIN
    ALTER TABLE dbo.[UserActivities] ADD CONSTRAINT FK_UserActivities_Users_UserId 
    FOREIGN KEY ([UserId]) REFERENCES dbo.[Users]([UserId]) ON DELETE CASCADE;
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_UserActivities_UserId' AND object_id = OBJECT_ID(N'dbo.UserActivities'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_UserActivities_UserId ON dbo.[UserActivities]([UserId] ASC);
END
GO

-- ==========================================
-- 3. Create EntityChangeHistory Table
-- ==========================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'EntityChangeHistory' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[EntityChangeHistory] (
        [Id] BIGINT IDENTITY(1,1) NOT NULL,
        [TableName] NVARCHAR(100) NOT NULL,
        [TableId] NVARCHAR(100) NOT NULL,
        [ActionType] VARCHAR(20) NOT NULL,
        [OldValuesJson] NVARCHAR(MAX) NULL,
        [NewValuesJson] NVARCHAR(MAX) NULL,
        [ChangeSummary] NVARCHAR(MAX) NULL,
        [ChangedAt] DATETIME NOT NULL CONSTRAINT DF_EntityChangeHistory_ChangedAt DEFAULT GETDATE(),
        [ChangedBy] NVARCHAR(20) NOT NULL,

        CONSTRAINT PK_EntityChangeHistory PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT CK_EntityChangeHistory_ActionType CHECK ([ActionType] IN ('CREATE', 'UPDATE', 'DELETE'))
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_EntityChangeHistory_Users_ChangedBy')
BEGIN
    ALTER TABLE dbo.[EntityChangeHistory] ADD CONSTRAINT FK_EntityChangeHistory_Users_ChangedBy 
    FOREIGN KEY ([ChangedBy]) REFERENCES dbo.[Users]([UserId]);
END
GO

-- ==========================================
-- 4. Create ConstantSettings Table
-- ==========================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'ConstantSettings' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[ConstantSettings] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [Category] NVARCHAR(50) NOT NULL CONSTRAINT DF_ConstantSettings_Category DEFAULT 'General',
        [SettingKey] NVARCHAR(100) NOT NULL,
        [SettingValue] NVARCHAR(MAX) NOT NULL,
        [Description] NVARCHAR(500) NULL,
        [DataType] VARCHAR(20) NOT NULL CONSTRAINT DF_ConstantSettings_DataType DEFAULT 'String',
        [IsUserOverridable] BIT NOT NULL CONSTRAINT DF_ConstantSettings_IsUserOverridable DEFAULT 0,
        [IsActive] BIT NOT NULL CONSTRAINT DF_ConstantSettings_IsActive DEFAULT 1,
        [LastUpdatedAt] DATETIME NULL,
        [LastUpdatedBy] NVARCHAR(20) NULL,

        CONSTRAINT PK_ConstantSettings PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT UQ_ConstantSettings_SettingKey UNIQUE ([SettingKey] ASC),
        CONSTRAINT CK_ConstantSettings_DataType CHECK ([DataType] IN ('String', 'Number', 'Boolean', 'Json'))
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ConstantSettings_Users_LastUpdatedBy')
BEGIN
    ALTER TABLE dbo.[ConstantSettings] ADD CONSTRAINT FK_ConstantSettings_Users_LastUpdatedBy 
    FOREIGN KEY ([LastUpdatedBy]) REFERENCES dbo.[Users]([UserId]);
END
GO

-- ==========================================
-- 5. Create UserSettings Table
-- ==========================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'UserSettings' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[UserSettings] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [ConstantSettingId] INT NULL,
        [UserId] NVARCHAR(20) NOT NULL,
        [Category] NVARCHAR(50) NOT NULL,
        [SettingKey] NVARCHAR(100) NOT NULL,
        [SettingValue] NVARCHAR(MAX) NOT NULL,
        [LastUpdatedAt] DATETIME NOT NULL CONSTRAINT DF_UserSettings_LastUpdatedAt DEFAULT GETDATE(),

        CONSTRAINT PK_UserSettings PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT UQ_UserSettings_User_Category_Key UNIQUE ([UserId] ASC, [Category] ASC, [SettingKey] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_UserSettings_ConstantSettings_ConstantSettingId')
BEGIN
    ALTER TABLE dbo.[UserSettings] ADD CONSTRAINT FK_UserSettings_ConstantSettings_ConstantSettingId 
    FOREIGN KEY ([ConstantSettingId]) REFERENCES dbo.[ConstantSettings]([Id]) ON DELETE SET NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_UserSettings_Users_UserId')
BEGIN
    ALTER TABLE dbo.[UserSettings] ADD CONSTRAINT FK_UserSettings_Users_UserId 
    FOREIGN KEY ([UserId]) REFERENCES dbo.[Users]([UserId]) ON DELETE CASCADE;
END
GO

-- ==========================================
-- 6. Create SoapAppAuthentication Table
-- ==========================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'SoapAppAuthentication' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[SoapAppAuthentication] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [AuthenticationType] VARCHAR(50) NOT NULL,
        [EncryptedCredentialsJson] NVARCHAR(MAX) NOT NULL,
        [IsActive] BIT NOT NULL CONSTRAINT DF_SoapAppAuthentication_IsActive DEFAULT 1,
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_SoapAppAuthentication_CreatedAt DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL,
        [LastUpdatedAt] DATETIME NULL,
        [LastUpdatedBy] NVARCHAR(20) NULL,

        CONSTRAINT PK_SoapAppAuthentication PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT CK_SoapAppAuthentication_Type CHECK ([AuthenticationType] IN ('Basic', 'NTLM', 'APIKey', 'OAuth2'))
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapAppAuthentication_Users_CreatedBy')
BEGIN
    ALTER TABLE dbo.[SoapAppAuthentication] ADD CONSTRAINT FK_SoapAppAuthentication_Users_CreatedBy 
    FOREIGN KEY ([CreatedBy]) REFERENCES dbo.[Users]([UserId]);
END
GO

-- ==========================================
-- 7. Create SoapApplications Table
-- ==========================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'SoapApplications' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[SoapApplications] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [SoapAppAuthenticationId] INT NULL,
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
        CONSTRAINT UIX_SoapApplications_AppName UNIQUE ([AppName] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapApplications_SoapAppAuthentication_AuthenticationId')
BEGIN
    ALTER TABLE dbo.[SoapApplications] ADD CONSTRAINT FK_SoapApplications_SoapAppAuthentication_AuthenticationId 
    FOREIGN KEY ([SoapAppAuthenticationId]) REFERENCES dbo.[SoapAppAuthentication]([Id]) ON DELETE SET NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapApplications_Users_CreatedBy')
BEGIN
    ALTER TABLE dbo.[SoapApplications] ADD CONSTRAINT FK_SoapApplications_Users_CreatedBy 
    FOREIGN KEY ([CreatedBy]) REFERENCES dbo.[Users]([UserId]);
END
GO

-- ==========================================
-- 8. Create SoapWsdlSync Table
-- ==========================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'SoapWsdlSync' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[SoapWsdlSync] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [AppId] INT NOT NULL,
        [WsdlUrl] NVARCHAR(500) NULL,
        [WsdlContent] VARBINARY(MAX) NOT NULL,
        [UncompressedSizeBytes] INT NULL,
        [FileHash] VARCHAR(64) NULL,
        [Version] VARCHAR(50) NOT NULL,
        [SyncedAt] DATETIME NOT NULL CONSTRAINT DF_SoapWsdlSync_SyncedAt DEFAULT GETDATE(),
        [SyncedBy] NVARCHAR(20) NOT NULL,

        CONSTRAINT PK_SoapWsdlSync PRIMARY KEY CLUSTERED ([Id] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapWsdlSync_SoapApplications_AppId')
BEGIN
    ALTER TABLE dbo.[SoapWsdlSync] ADD CONSTRAINT FK_SoapWsdlSync_SoapApplications_AppId 
    FOREIGN KEY ([AppId]) REFERENCES dbo.[SoapApplications]([Id]) ON DELETE CASCADE;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapWsdlSync_Users_SyncedBy')
BEGIN
    ALTER TABLE dbo.[SoapWsdlSync] ADD CONSTRAINT FK_SoapWsdlSync_Users_SyncedBy 
    FOREIGN KEY ([SyncedBy]) REFERENCES dbo.[Users]([UserId]);
END
GO

-- ==========================================
-- 9. Create SoapWsdlSyncHistory Table
-- ==========================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'SoapWsdlSyncHistory' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[SoapWsdlSyncHistory] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [WsdlSyncId] INT NOT NULL,
        [Version] VARCHAR(50) NOT NULL,
        [WsdlContent] VARBINARY(MAX) NULL,
        [DiffContent] VARBINARY(MAX) NULL,
        [UncompressedSizeBytes] INT NULL,
        [FileHash] VARCHAR(64) NULL,
        [SystemLog] NVARCHAR(MAX) NOT NULL,
        [Comment] NVARCHAR(MAX) NULL,
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_SoapWsdlSyncHistory_CreatedAt DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL,

        CONSTRAINT PK_SoapWsdlSyncHistory PRIMARY KEY CLUSTERED ([Id] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapWsdlSyncHistory_SoapWsdlSync_WsdlSyncId')
BEGIN
    ALTER TABLE dbo.[SoapWsdlSyncHistory] ADD CONSTRAINT FK_SoapWsdlSyncHistory_SoapWsdlSync_WsdlSyncId 
    FOREIGN KEY ([WsdlSyncId]) REFERENCES dbo.[SoapWsdlSync]([Id]) ON DELETE CASCADE;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapWsdlSyncHistory_Users_CreatedBy')
BEGIN
    ALTER TABLE dbo.[SoapWsdlSyncHistory] ADD CONSTRAINT FK_SoapWsdlSyncHistory_Users_CreatedBy 
    FOREIGN KEY ([CreatedBy]) REFERENCES dbo.[Users]([UserId]);
END
GO

-- ==========================================
-- 10. Create SoapOperations Table
-- ==========================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'SoapOperations' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[SoapOperations] (
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
        CONSTRAINT UIX_SoapOperations_WsdlSyncId_OpName UNIQUE ([WsdlSyncId] ASC, [OperationName] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapOperations_SoapApplications_AppId')
BEGIN
    ALTER TABLE dbo.[SoapOperations] ADD CONSTRAINT FK_SoapOperations_SoapApplications_AppId 
    FOREIGN KEY ([AppId]) REFERENCES dbo.[SoapApplications]([Id]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapOperations_SoapWsdlSync_WsdlSyncId')
BEGIN
    ALTER TABLE dbo.[SoapOperations] ADD CONSTRAINT FK_SoapOperations_SoapWsdlSync_WsdlSyncId 
    FOREIGN KEY ([WsdlSyncId]) REFERENCES dbo.[SoapWsdlSync]([Id]) ON DELETE CASCADE;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapOperations_Users_CreatedBy')
BEGIN
    ALTER TABLE dbo.[SoapOperations] ADD CONSTRAINT FK_SoapOperations_Users_CreatedBy 
    FOREIGN KEY ([CreatedBy]) REFERENCES dbo.[Users]([UserId]);
END
GO

-- ==========================================
-- 11. Create SoapRequestFiles Table
-- ==========================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'SoapRequestFiles' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[SoapRequestFiles] (
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

        CONSTRAINT PK_SoapRequestFiles PRIMARY KEY CLUSTERED ([Id] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapRequestFiles_SoapOperations_OperationId')
BEGIN
    ALTER TABLE dbo.[SoapRequestFiles] ADD CONSTRAINT FK_SoapRequestFiles_SoapOperations_OperationId 
    FOREIGN KEY ([OperationId]) REFERENCES dbo.[SoapOperations]([Id]) ON DELETE CASCADE;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapRequestFiles_Users_CreatedBy')
BEGIN
    ALTER TABLE dbo.[SoapRequestFiles] ADD CONSTRAINT FK_SoapRequestFiles_Users_CreatedBy 
    FOREIGN KEY ([CreatedBy]) REFERENCES dbo.[Users]([UserId]);
END
GO

-- ==========================================
-- 12. Create SoapRequestFileHistory Table
-- ==========================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'SoapRequestFileHistory' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[SoapRequestFileHistory] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [RequestFileId] INT NOT NULL,
        [Version] VARCHAR(50) NOT NULL,
        [FileData] VARBINARY(MAX) NULL,
        [DiffData] VARBINARY(MAX) NULL,
        [UncompressedSizeBytes] INT NULL,
        [FileHash] VARCHAR(64) NULL,
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_SoapRequestFileHistory_CreatedAt DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL,

        CONSTRAINT PK_SoapRequestFileHistory PRIMARY KEY CLUSTERED ([Id] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapRequestFileHistory_SoapRequestFiles_RequestFileId')
BEGIN
    ALTER TABLE dbo.[SoapRequestFileHistory] ADD CONSTRAINT FK_SoapRequestFileHistory_SoapRequestFiles_RequestFileId 
    FOREIGN KEY ([RequestFileId]) REFERENCES dbo.[SoapRequestFiles]([Id]) ON DELETE CASCADE;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapRequestFileHistory_Users_CreatedBy')
BEGIN
    ALTER TABLE dbo.[SoapRequestFileHistory] ADD CONSTRAINT FK_SoapRequestFileHistory_Users_CreatedBy 
    FOREIGN KEY ([CreatedBy]) REFERENCES dbo.[Users]([UserId]);
END
GO

-- ==========================================
-- 13. Create SoapExecutionGroups Table
-- ==========================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'SoapExecutionGroups' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[SoapExecutionGroups] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [AppId] INT NULL,
        [GroupName] NVARCHAR(200) NOT NULL,
        [Description] NVARCHAR(MAX) NULL,
        [IsActive] BIT NOT NULL CONSTRAINT DF_SoapExecutionGroups_IsActive DEFAULT 1,
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_SoapExecutionGroups_CreatedAt DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL,
        [LastUpdatedAt] DATETIME NULL,
        [LastUpdatedBy] NVARCHAR(20) NULL,

        CONSTRAINT PK_SoapExecutionGroups PRIMARY KEY CLUSTERED ([Id] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapExecutionGroups_SoapApplications_AppId')
BEGIN
    ALTER TABLE dbo.[SoapExecutionGroups] ADD CONSTRAINT FK_SoapExecutionGroups_SoapApplications_AppId 
    FOREIGN KEY ([AppId]) REFERENCES dbo.[SoapApplications]([Id]) ON DELETE SET NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapExecutionGroups_Users_CreatedBy')
BEGIN
    ALTER TABLE dbo.[SoapExecutionGroups] ADD CONSTRAINT FK_SoapExecutionGroups_Users_CreatedBy 
    FOREIGN KEY ([CreatedBy]) REFERENCES dbo.[Users]([UserId]);
END
GO

-- ==========================================
-- 14. Create SoapExecutionGroupItems Table
-- ==========================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'SoapExecutionGroupItems' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[SoapExecutionGroupItems] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [ExecutionGroupId] INT NOT NULL,
        [RequestFileId] INT NOT NULL,
        [RequestFileHistoryId] INT NULL,
        [ExecutionOrder] INT NOT NULL CONSTRAINT DF_SoapExecutionGroupItems_ExecutionOrder DEFAULT 1,
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_SoapExecutionGroupItems_CreatedAt DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL,

        CONSTRAINT PK_SoapExecutionGroupItems PRIMARY KEY CLUSTERED ([Id] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapExecutionGroupItems_SoapExecutionGroups_ExecutionGroupId')
BEGIN
    ALTER TABLE dbo.[SoapExecutionGroupItems] ADD CONSTRAINT FK_SoapExecutionGroupItems_SoapExecutionGroups_ExecutionGroupId 
    FOREIGN KEY ([ExecutionGroupId]) REFERENCES dbo.[SoapExecutionGroups]([Id]) ON DELETE CASCADE;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapExecutionGroupItems_SoapRequestFiles_RequestFileId')
BEGIN
    ALTER TABLE dbo.[SoapExecutionGroupItems] ADD CONSTRAINT FK_SoapExecutionGroupItems_SoapRequestFiles_RequestFileId 
    FOREIGN KEY ([RequestFileId]) REFERENCES dbo.[SoapRequestFiles]([Id]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapExecutionGroupItems_SoapRequestFileHistory_RequestFileHistoryId')
BEGIN
    ALTER TABLE dbo.[SoapExecutionGroupItems] ADD CONSTRAINT FK_SoapExecutionGroupItems_SoapRequestFileHistory_RequestFileHistoryId 
    FOREIGN KEY ([RequestFileHistoryId]) REFERENCES dbo.[SoapRequestFileHistory]([Id]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapExecutionGroupItems_Users_CreatedBy')
BEGIN
    ALTER TABLE dbo.[SoapExecutionGroupItems] ADD CONSTRAINT FK_SoapExecutionGroupItems_Users_CreatedBy 
    FOREIGN KEY ([CreatedBy]) REFERENCES dbo.[Users]([UserId]);
END
GO

-- ==========================================
-- 15. Create SoapExecutionRuns Table
-- ==========================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'SoapExecutionRuns' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[SoapExecutionRuns] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [ExecutionGroupId] INT NOT NULL,
        [RunStatus] VARCHAR(20) NOT NULL CONSTRAINT DF_SoapExecutionRuns_RunStatus DEFAULT 'Pending',
        [ExecutedBy] NVARCHAR(20) NOT NULL,
        [StartedAt] DATETIME NOT NULL CONSTRAINT DF_SoapExecutionRuns_StartedAt DEFAULT GETDATE(),
        [CompletedAt] DATETIME NULL,
        [CancelledAt] DATETIME NULL,

        CONSTRAINT PK_SoapExecutionRuns PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT CK_SoapExecutionRuns_RunStatus CHECK ([RunStatus] IN ('Pending', 'InProgress', 'Completed', 'Failed', 'Cancelled'))
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapExecutionRuns_SoapExecutionGroups_ExecutionGroupId')
BEGIN
    ALTER TABLE dbo.[SoapExecutionRuns] ADD CONSTRAINT FK_SoapExecutionRuns_SoapExecutionGroups_ExecutionGroupId 
    FOREIGN KEY ([ExecutionGroupId]) REFERENCES dbo.[SoapExecutionGroups]([Id]) ON DELETE CASCADE;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapExecutionRuns_Users_ExecutedBy')
BEGIN
    ALTER TABLE dbo.[SoapExecutionRuns] ADD CONSTRAINT FK_SoapExecutionRuns_Users_ExecutedBy 
    FOREIGN KEY ([ExecutedBy]) REFERENCES dbo.[Users]([UserId]);
END
GO

-- ==========================================
-- 16. Create SoapExecutionItemRuns Table
-- ==========================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'SoapExecutionItemRuns' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[SoapExecutionItemRuns] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [ExecutionRunId] INT NOT NULL,
        [ExecutionGroupItemId] INT NOT NULL,
        [ItemExecutionStatus] VARCHAR(20) NOT NULL CONSTRAINT DF_SoapExecutionItemRuns_Status DEFAULT 'Pending',
        [ExecutedAt] DATETIME NOT NULL CONSTRAINT DF_SoapExecutionItemRuns_ExecutedAt DEFAULT GETDATE(),
        [ExecutedBy] NVARCHAR(20) NOT NULL,
        [HttpStatusCode] INT NULL,
        [ExecutionTimeMs] INT NULL,
        [CancelledAt] DATETIME NULL,

        CONSTRAINT PK_SoapExecutionItemRuns PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT CK_SoapExecutionItemRuns_Status CHECK ([ItemExecutionStatus] IN ('Pending', 'InProgress', 'Success', 'Failure', 'Skipped', 'Cancelled'))
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapExecutionItemRuns_SoapExecutionRuns_ExecutionRunId')
BEGIN
    ALTER TABLE dbo.[SoapExecutionItemRuns] ADD CONSTRAINT FK_SoapExecutionItemRuns_SoapExecutionRuns_ExecutionRunId 
    FOREIGN KEY ([ExecutionRunId]) REFERENCES dbo.[SoapExecutionRuns]([Id]) ON DELETE CASCADE;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapExecutionItemRuns_SoapExecutionGroupItems_ExecutionGroupItemId')
BEGIN
    ALTER TABLE dbo.[SoapExecutionItemRuns] ADD CONSTRAINT FK_SoapExecutionItemRuns_SoapExecutionGroupItems_ExecutionGroupItemId 
    FOREIGN KEY ([ExecutionGroupItemId]) REFERENCES dbo.[SoapExecutionGroupItems]([Id]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapExecutionItemRuns_Users_ExecutedBy')
BEGIN
    ALTER TABLE dbo.[SoapExecutionItemRuns] ADD CONSTRAINT FK_SoapExecutionItemRuns_Users_ExecutedBy 
    FOREIGN KEY ([ExecutedBy]) REFERENCES dbo.[Users]([UserId]);
END
GO

-- ==========================================
-- 17. Create SoapResponseFiles Table
-- ==========================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'SoapResponseFiles' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[SoapResponseFiles] (
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
        CONSTRAINT CK_SoapResponseFiles_Format CHECK ([ResponseFormat] IS NULL OR [ResponseFormat] IN ('XML','JSON','PDF','BINARY'))
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapResponseFiles_SoapExecutionItemRuns_ExecutionItemRunId')
BEGIN
    ALTER TABLE dbo.[SoapResponseFiles] ADD CONSTRAINT FK_SoapResponseFiles_SoapExecutionItemRuns_ExecutionItemRunId 
    FOREIGN KEY ([ExecutionItemRunId]) REFERENCES dbo.[SoapExecutionItemRuns]([Id]) ON DELETE CASCADE;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapResponseFiles_Users_CreatedBy')
BEGIN
    ALTER TABLE dbo.[SoapResponseFiles] ADD CONSTRAINT FK_SoapResponseFiles_Users_CreatedBy 
    FOREIGN KEY ([CreatedBy]) REFERENCES dbo.[Users]([UserId]);
END
GO

-- ==========================================
-- 18. Create SoapResponseEmbeddings Table
-- ==========================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'SoapResponseEmbeddings' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[SoapResponseEmbeddings] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [ResponseFileId] INT NOT NULL,
        [AttachmentName] NVARCHAR(250) NOT NULL,
        [ContentType] NVARCHAR(100) NOT NULL,
        [FileData] VARBINARY(MAX) NOT NULL,
        [UncompressedSizeBytes] INT NULL,
        [FileHash] VARCHAR(64) NULL,
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_SoapResponseEmbeddings_CreatedAt DEFAULT GETDATE(),

        CONSTRAINT PK_SoapResponseEmbeddings PRIMARY KEY CLUSTERED ([Id] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapResponseEmbeddings_SoapResponseFiles_ResponseFileId')
BEGIN
    ALTER TABLE dbo.[SoapResponseEmbeddings] ADD CONSTRAINT FK_SoapResponseEmbeddings_SoapResponseFiles_ResponseFileId 
    FOREIGN KEY ([ResponseFileId]) REFERENCES dbo.[SoapResponseFiles]([Id]) ON DELETE CASCADE;
END
GO

-- ==========================================
-- 19. Create SoapResponseFileHistory Table
-- ==========================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'SoapResponseFileHistory' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[SoapResponseFileHistory] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [ResponseFileId] INT NOT NULL,
        [Version] VARCHAR(50) NOT NULL,
        [FileData] VARBINARY(MAX) NULL,
        [DiffData] VARBINARY(MAX) NULL,
        [UncompressedSizeBytes] INT NULL,
        [FileHash] VARCHAR(64) NULL,
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_SoapResponseFileHistory_CreatedAt DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL,

        CONSTRAINT PK_SoapResponseFileHistory PRIMARY KEY CLUSTERED ([Id] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapResponseFileHistory_SoapResponseFiles_ResponseFileId')
BEGIN
    ALTER TABLE dbo.[SoapResponseFileHistory] ADD CONSTRAINT FK_SoapResponseFileHistory_SoapResponseFiles_ResponseFileId 
    FOREIGN KEY ([ResponseFileId]) REFERENCES dbo.[SoapResponseFiles]([Id]) ON DELETE CASCADE;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapResponseFileHistory_Users_CreatedBy')
BEGIN
    ALTER TABLE dbo.[SoapResponseFileHistory] ADD CONSTRAINT FK_SoapResponseFileHistory_Users_CreatedBy 
    FOREIGN KEY ([CreatedBy]) REFERENCES dbo.[Users]([UserId]);
END
GO

-- ==========================================
-- 20. Create SoapOperationSchemas Table
-- ==========================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'SoapOperationSchemas' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[SoapOperationSchemas] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [WsdlSyncId] INT NOT NULL,
        [OperationId] INT NULL,
        [TargetNamespace] NVARCHAR(500) NULL,
        [XsdContent] NVARCHAR(MAX) NOT NULL,
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_SoapOperationSchemas_CreatedAt DEFAULT GETDATE(),

        CONSTRAINT PK_SoapOperationSchemas PRIMARY KEY CLUSTERED ([Id] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapOperationSchemas_SoapWsdlSync_WsdlSyncId')
BEGIN
    ALTER TABLE dbo.[SoapOperationSchemas] ADD CONSTRAINT FK_SoapOperationSchemas_SoapWsdlSync_WsdlSyncId 
    FOREIGN KEY ([WsdlSyncId]) REFERENCES dbo.[SoapWsdlSync]([Id]) ON DELETE CASCADE;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapOperationSchemas_SoapOperations_OperationId')
BEGIN
    ALTER TABLE dbo.[SoapOperationSchemas] ADD CONSTRAINT FK_SoapOperationSchemas_SoapOperations_OperationId 
    FOREIGN KEY ([OperationId]) REFERENCES dbo.[SoapOperations]([Id]);
END
GO

-- ==========================================
-- 21. Create SoapNamespaces Table
-- ==========================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'SoapNamespaces' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[SoapNamespaces] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [WsdlSyncId] INT NOT NULL,
        [OperationId] INT NULL,
        [Prefix] NVARCHAR(50) NOT NULL,
        [NamespaceUri] NVARCHAR(500) NOT NULL,
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_SoapNamespaces_CreatedAt DEFAULT GETDATE(),

        CONSTRAINT PK_SoapNamespaces PRIMARY KEY CLUSTERED ([Id] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapNamespaces_SoapWsdlSync_WsdlSyncId')
BEGIN
    ALTER TABLE dbo.[SoapNamespaces] ADD CONSTRAINT FK_SoapNamespaces_SoapWsdlSync_WsdlSyncId 
    FOREIGN KEY ([WsdlSyncId]) REFERENCES dbo.[SoapWsdlSync]([Id]) ON DELETE CASCADE;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapNamespaces_SoapOperations_OperationId')
BEGIN
    ALTER TABLE dbo.[SoapNamespaces] ADD CONSTRAINT FK_SoapNamespaces_SoapOperations_OperationId 
    FOREIGN KEY ([OperationId]) REFERENCES dbo.[SoapOperations]([Id]);
END
GO