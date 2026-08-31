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
-- Optional Tear-Down (Drop FKs, Indexes, and Tables)
-- Logic Note: Dropping a table automatically cleans up its PKs, 
-- defaults, checks, indexes, and sp_extendedproperties. Foreign keys referencing
-- or living on the tables are dropped systematically here first.
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
    DROP TABLE IF EXISTS dbo.[TestCaseValidationRules];
    DROP TABLE IF EXISTS dbo.[TestCases];
    DROP TABLE IF EXISTS dbo.[TestSuites];
    DROP TABLE IF EXISTS dbo.[SoapExecutionGroupPermissions];
    DROP TABLE IF EXISTS dbo.[SoapRequestFilePermissions];
    DROP TABLE IF EXISTS dbo.[SoapAppPermissions];
    DROP TABLE IF EXISTS dbo.[SoapOperationSchemas];
    DROP TABLE IF EXISTS dbo.[SoapNamespaces];
    DROP TABLE IF EXISTS dbo.[SoapResponseEmbeddings];
    DROP TABLE IF EXISTS dbo.[SoapResponseFileHistory];
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
-- Logic Note: Stores system identity and Windows credentials.
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

-- Column & Table Extended Properties for Users
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'System user accounts and profiles.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Users';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Windows Domain\Username login identity.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Users', @level2type=N'COLUMN',@level2name=N'UserId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Primary email address.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Users', @level2type=N'COLUMN',@level2name=N'Email';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Department affiliation.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Users', @level2type=N'COLUMN',@level2name=N'Department';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Given first name.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Users', @level2type=N'COLUMN',@level2name=N'FirstName';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Family last name.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Users', @level2type=N'COLUMN',@level2name=N'LastName';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Role assignment within the system.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Users', @level2type=N'COLUMN',@level2name=N'Role';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Flag indicating active account state.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Users', @level2type=N'COLUMN',@level2name=N'IsActive';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'User who created this account record.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Users', @level2type=N'COLUMN',@level2name=N'CreatedBy';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Timestamp of account creation.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Users', @level2type=N'COLUMN',@level2name=N'CreatedDate';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Timestamp when record was last updated.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Users', @level2type=N'COLUMN',@level2name=N'LastUpdatedAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'User who last modified this record.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Users', @level2type=N'COLUMN',@level2name=N'LastUpdatedBy';
GO

-- ==========================================
-- 2. Create UserActivities Table
-- Logic Note: Logs system usage, feature telemetry, and user interactions.
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

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_UserActivities_Timestamp' AND object_id = OBJECT_ID(N'dbo.UserActivities'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_UserActivities_Timestamp ON dbo.[UserActivities]([Timestamp] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_UserActivities_TableName_TableId' AND object_id = OBJECT_ID(N'dbo.UserActivities'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_UserActivities_TableName_TableId ON dbo.[UserActivities]([TableName] ASC, [TableId] ASC);
END
GO

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Audit log for individual user actions and UI interactions.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'UserActivities';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Surrogate primary key.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'UserActivities', @level2type=N'COLUMN',@level2name=N'Id';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'User who performed the activity.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'UserActivities', @level2type=N'COLUMN',@level2name=N'UserId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Application feature or module accessed.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'UserActivities', @level2type=N'COLUMN',@level2name=N'FeatureName';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Associated target entity table name.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'UserActivities', @level2type=N'COLUMN',@level2name=N'TableName';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Associated target entity primary key value.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'UserActivities', @level2type=N'COLUMN',@level2name=N'TableId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Detailed activity telemetry in JSON or plain text format.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'UserActivities', @level2type=N'COLUMN',@level2name=N'FeatureActivities';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Timestamp when action occurred.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'UserActivities', @level2type=N'COLUMN',@level2name=N'Timestamp';
GO

-- ==========================================
-- 3. Create EntityChangeHistory Table
-- Logic Note: Universal data audit log tracking entity inserts, updates, and deletes.
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

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_EntityChangeHistory_Table' AND object_id = OBJECT_ID(N'dbo.EntityChangeHistory'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_EntityChangeHistory_Table ON dbo.[EntityChangeHistory]([TableName] ASC, [TableId] ASC);
END
GO

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'System-wide audit trail for entity mutations.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'EntityChangeHistory';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Audit record unique identifier.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'EntityChangeHistory', @level2type=N'COLUMN',@level2name=N'Id';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Target database table altered.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'EntityChangeHistory', @level2type=N'COLUMN',@level2name=N'TableName';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Target row primary key.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'EntityChangeHistory', @level2type=N'COLUMN',@level2name=N'TableId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Mutation type: CREATE, UPDATE, DELETE.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'EntityChangeHistory', @level2type=N'COLUMN',@level2name=N'ActionType';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'JSON snapshot of entity state prior to mutation.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'EntityChangeHistory', @level2type=N'COLUMN',@level2name=N'OldValuesJson';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'JSON snapshot of entity state following mutation.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'EntityChangeHistory', @level2type=N'COLUMN',@level2name=N'NewValuesJson';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Human readable delta description.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'EntityChangeHistory', @level2type=N'COLUMN',@level2name=N'ChangeSummary';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Timestamp of change.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'EntityChangeHistory', @level2type=N'COLUMN',@level2name=N'ChangedAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'User responsible for change.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'EntityChangeHistory', @level2type=N'COLUMN',@level2name=N'ChangedBy';
GO

-- ==========================================
-- 4. Create ConstantSettings Table
-- Logic Note: System-wide global configuration defaults.
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

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_ConstantSettings_IsActive' AND object_id = OBJECT_ID(N'dbo.ConstantSettings'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_ConstantSettings_IsActive ON dbo.[ConstantSettings]([IsActive] ASC);
END
GO

-- Seed Baseline Settings
IF NOT EXISTS (SELECT 1 FROM dbo.[ConstantSettings] WHERE [SettingKey] = 'RequestFileDiffCount')
BEGIN
    INSERT INTO dbo.[ConstantSettings] ([SettingKey], [SettingValue], [Description], [IsActive])
    VALUES ('RequestFileDiffCount', '5', 'Number of diff payload increments retained in history before forcing full base file snapshot', 1);
END
GO

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Global system application baseline properties and configurations.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ConstantSettings';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Primary key identifier.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ConstantSettings', @level2type=N'COLUMN',@level2name=N'Id';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Setting grouping category (e.g. System, Theme, Grid).', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ConstantSettings', @level2type=N'COLUMN',@level2name=N'Category';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Unique configuration lookup key.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ConstantSettings', @level2type=N'COLUMN',@level2name=N'SettingKey';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Configuration value or JSON payload.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ConstantSettings', @level2type=N'COLUMN',@level2name=N'SettingValue';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Human description of setting purpose.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ConstantSettings', @level2type=N'COLUMN',@level2name=N'Description';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Value type descriptor (String, Number, Boolean, Json).', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ConstantSettings', @level2type=N'COLUMN',@level2name=N'DataType';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Flag indicating if individual users can override this setting.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ConstantSettings', @level2type=N'COLUMN',@level2name=N'IsUserOverridable';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Flag indicating active status.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ConstantSettings', @level2type=N'COLUMN',@level2name=N'IsActive';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Last change timestamp.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ConstantSettings', @level2type=N'COLUMN',@level2name=N'LastUpdatedAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'User who last modified setting.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'ConstantSettings', @level2type=N'COLUMN',@level2name=N'LastUpdatedBy';
GO

-- ==========================================
-- 5. Create UserSettings Table
-- Logic Note: User-specific configuration overrides referencing ConstantSettings.
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

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_UserSettings_UserId_Category' AND object_id = OBJECT_ID(N'dbo.UserSettings'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_UserSettings_UserId_Category ON dbo.[UserSettings]([UserId] ASC, [Category] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_UserSettings_SettingKey' AND object_id = OBJECT_ID(N'dbo.UserSettings'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_UserSettings_SettingKey ON dbo.[UserSettings]([SettingKey] ASC);
END
GO

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'User-level preference overrides for system configuration.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'UserSettings';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Primary key identifier.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'UserSettings', @level2type=N'COLUMN',@level2name=N'Id';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Optional reference to underlying constant baseline setting.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'UserSettings', @level2type=N'COLUMN',@level2name=N'ConstantSettingId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'User owning this override.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'UserSettings', @level2type=N'COLUMN',@level2name=N'UserId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Setting category.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'UserSettings', @level2type=N'COLUMN',@level2name=N'Category';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Setting key name.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'UserSettings', @level2type=N'COLUMN',@level2name=N'SettingKey';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'User-defined setting override value.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'UserSettings', @level2type=N'COLUMN',@level2name=N'SettingValue';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Timestamp of last modification.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'UserSettings', @level2type=N'COLUMN',@level2name=N'LastUpdatedAt';
GO

-- ==========================================
-- 6. Create SoapAppAuthentication Table
-- Logic Note: Precedes SoapApplications to support 1:1/1:N optional authentication bindings.
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

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapAppAuthentication_Users_LastUpdatedBy')
BEGIN
    ALTER TABLE dbo.[SoapAppAuthentication] ADD CONSTRAINT FK_SoapAppAuthentication_Users_LastUpdatedBy 
    FOREIGN KEY ([LastUpdatedBy]) REFERENCES dbo.[Users]([UserId]);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapAppAuthentication_IsActive' AND object_id = OBJECT_ID(N'dbo.SoapAppAuthentication'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapAppAuthentication_IsActive ON dbo.[SoapAppAuthentication]([IsActive] ASC);
END
GO

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Authentication configurations and encrypted key storage.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapAppAuthentication';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Primary key identifier.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapAppAuthentication', @level2type=N'COLUMN',@level2name=N'Id';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Authentication type (Basic, NTLM, APIKey, OAuth2).', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapAppAuthentication', @level2type=N'COLUMN',@level2name=N'AuthenticationType';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Encrypted credential data JSON.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapAppAuthentication', @level2type=N'COLUMN',@level2name=N'EncryptedCredentialsJson';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Active flag.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapAppAuthentication', @level2type=N'COLUMN',@level2name=N'IsActive';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Creation timestamp.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapAppAuthentication', @level2type=N'COLUMN',@level2name=N'CreatedAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'User who created record.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapAppAuthentication', @level2type=N'COLUMN',@level2name=N'CreatedBy';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Last update timestamp.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapAppAuthentication', @level2type=N'COLUMN',@level2name=N'LastUpdatedAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'User who modified record.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapAppAuthentication', @level2type=N'COLUMN',@level2name=N'LastUpdatedBy';
GO

-- ==========================================
-- 7. Create SoapApplications Table
-- Logic Note: Top-level entity for application boundaries. Contains FK to optional SoapAppAuthentication.
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

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapApplications_Users_LastUpdatedBy')
BEGIN
    ALTER TABLE dbo.[SoapApplications] ADD CONSTRAINT FK_SoapApplications_Users_LastUpdatedBy 
    FOREIGN KEY ([LastUpdatedBy]) REFERENCES dbo.[Users]([UserId]);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapApplications_AppName' AND object_id = OBJECT_ID(N'dbo.SoapApplications'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapApplications_AppName ON dbo.[SoapApplications]([AppName] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapApplications_IsActive' AND object_id = OBJECT_ID(N'dbo.SoapApplications'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapApplications_IsActive ON dbo.[SoapApplications]([IsActive] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapApplications_CreatedBy' AND object_id = OBJECT_ID(N'dbo.SoapApplications'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapApplications_CreatedBy ON dbo.[SoapApplications]([CreatedBy] ASC);
END
GO

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Target web service applications.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapApplications';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Primary key identifier.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapApplications', @level2type=N'COLUMN',@level2name=N'Id';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Foreign key to authentication profile.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapApplications', @level2type=N'COLUMN',@level2name=N'SoapAppAuthenticationId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Unique application name.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapApplications', @level2type=N'COLUMN',@level2name=N'AppName';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Base service host URL.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapApplications', @level2type=N'COLUMN',@level2name=N'BaseUrl';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Relative URL to fetch WSDL document.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapApplications', @level2type=N'COLUMN',@level2name=N'WsdlRelativeUrl';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Relative endpoint for health checks.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapApplications', @level2type=N'COLUMN',@level2name=N'HealthcheckRelativeUrl';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Application description.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapApplications', @level2type=N'COLUMN',@level2name=N'Description';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Active status flag.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapApplications', @level2type=N'COLUMN',@level2name=N'IsActive';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Application release version.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapApplications', @level2type=N'COLUMN',@level2name=N'Version';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Created timestamp.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapApplications', @level2type=N'COLUMN',@level2name=N'CreatedAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Creator user.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapApplications', @level2type=N'COLUMN',@level2name=N'CreatedBy';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Last updated timestamp.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapApplications', @level2type=N'COLUMN',@level2name=N'LastUpdatedAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'User who updated record.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapApplications', @level2type=N'COLUMN',@level2name=N'LastUpdatedBy';
GO

-- ==========================================
-- 8. Create SoapWsdlSync Table
-- Logic Note: Holds compressed binary WSDL document content along with hash and version metadata.
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

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapWsdlSync_AppId' AND object_id = OBJECT_ID(N'dbo.SoapWsdlSync'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapWsdlSync_AppId ON dbo.[SoapWsdlSync]([AppId] ASC);
END
GO

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Active state synchronized WSDL documents.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapWsdlSync';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Primary key identifier.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapWsdlSync', @level2type=N'COLUMN',@level2name=N'Id';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Parent application ID.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapWsdlSync', @level2type=N'COLUMN',@level2name=N'AppId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Originating URL of synchronized WSDL.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapWsdlSync', @level2type=N'COLUMN',@level2name=N'WsdlUrl';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'GZIP/deflate compressed WSDL payload bytes.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapWsdlSync', @level2type=N'COLUMN',@level2name=N'WsdlContent';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Uncompressed file size in bytes.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapWsdlSync', @level2type=N'COLUMN',@level2name=N'UncompressedSizeBytes';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'SHA-256 hash of raw file content.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapWsdlSync', @level2type=N'COLUMN',@level2name=N'FileHash';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Synchronized schema version string.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapWsdlSync', @level2type=N'COLUMN',@level2name=N'Version';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Synchronization timestamp.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapWsdlSync', @level2type=N'COLUMN',@level2name=N'SyncedAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'User who performed synchronization.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapWsdlSync', @level2type=N'COLUMN',@level2name=N'SyncedBy';
GO

-- ==========================================
-- 9. Create SoapWsdlSyncHistory Table
-- Logic Note: Placed directly after SoapWsdlSync. Stores diffs and historical WSDL versions.
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

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapWsdlSyncHistory_WsdlSyncId' AND object_id = OBJECT_ID(N'dbo.SoapWsdlSyncHistory'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapWsdlSyncHistory_WsdlSyncId ON dbo.[SoapWsdlSyncHistory]([WsdlSyncId] ASC);
END
GO

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Audit and differential history log of WSDL schema updates.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapWsdlSyncHistory';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Primary key identifier.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapWsdlSyncHistory', @level2type=N'COLUMN',@level2name=N'Id';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Reference to parent WSDL sync record.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapWsdlSyncHistory', @level2type=N'COLUMN',@level2name=N'WsdlSyncId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Historical version string.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapWsdlSyncHistory', @level2type=N'COLUMN',@level2name=N'Version';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Compressed baseline WSDL content binary (populated during milestone saves).', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapWsdlSyncHistory', @level2type=N'COLUMN',@level2name=N'WsdlContent';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Compressed differential payload increment bytes relative to prior base.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapWsdlSyncHistory', @level2type=N'COLUMN',@level2name=N'DiffContent';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Uncompressed file byte count.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapWsdlSyncHistory', @level2type=N'COLUMN',@level2name=N'UncompressedSizeBytes';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'SHA-256 hash of payload.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapWsdlSyncHistory', @level2type=N'COLUMN',@level2name=N'FileHash';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Automated parser system event logs.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapWsdlSyncHistory', @level2type=N'COLUMN',@level2name=N'SystemLog';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'User comment.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapWsdlSyncHistory', @level2type=N'COLUMN',@level2name=N'Comment';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Creation timestamp.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapWsdlSyncHistory', @level2type=N'COLUMN',@level2name=N'CreatedAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'User who committed history increment.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapWsdlSyncHistory', @level2type=N'COLUMN',@level2name=N'CreatedBy';
GO

-- ==========================================
-- 10. Create SoapOperations Table
-- Logic Note: Defines distinct operations parsed out of synced WSDL documents.
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

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapOperations_Users_LastUpdatedBy')
BEGIN
    ALTER TABLE dbo.[SoapOperations] ADD CONSTRAINT FK_SoapOperations_Users_LastUpdatedBy 
    FOREIGN KEY ([LastUpdatedBy]) REFERENCES dbo.[Users]([UserId]);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapOperations_AppId' AND object_id = OBJECT_ID(N'dbo.SoapOperations'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapOperations_AppId ON dbo.[SoapOperations]([AppId] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapOperations_WsdlSyncId' AND object_id = OBJECT_ID(N'dbo.SoapOperations'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapOperations_WsdlSyncId ON dbo.[SoapOperations]([WsdlSyncId] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapOperations_IsActive' AND object_id = OBJECT_ID(N'dbo.SoapOperations'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapOperations_IsActive ON dbo.[SoapOperations]([IsActive] ASC);
END
GO

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'SOAP web service methods and endpoint actions.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapOperations';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Primary key identifier.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapOperations', @level2type=N'COLUMN',@level2name=N'Id';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Parent application ID.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapOperations', @level2type=N'COLUMN',@level2name=N'AppId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Originating WSDL sync ID.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapOperations', @level2type=N'COLUMN',@level2name=N'WsdlSyncId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Name of operation/method.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapOperations', @level2type=N'COLUMN',@level2name=N'OperationName';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Operation description.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapOperations', @level2type=N'COLUMN',@level2name=N'Description';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'SOAPAction header string.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapOperations', @level2type=N'COLUMN',@level2name=N'SoapAction';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Input message XML payload root element.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapOperations', @level2type=N'COLUMN',@level2name=N'InputRootElementName';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Output message XML payload root element.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapOperations', @level2type=N'COLUMN',@level2name=N'OutputRootElementName';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Active flag.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapOperations', @level2type=N'COLUMN',@level2name=N'IsActive';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Creation timestamp.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapOperations', @level2type=N'COLUMN',@level2name=N'CreatedAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Creator user.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapOperations', @level2type=N'COLUMN',@level2name=N'CreatedBy';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Last updated timestamp.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapOperations', @level2type=N'COLUMN',@level2name=N'LastUpdatedAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Modifier user.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapOperations', @level2type=N'COLUMN',@level2name=N'LastUpdatedBy';
GO

-- ==========================================
-- 11. Create SoapRequestFiles Table
-- Logic Note: Holds active SOAP request payloads. FileData contains compressed XML bytes.
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

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapRequestFiles_Users_LastUpdatedBy')
BEGIN
    ALTER TABLE dbo.[SoapRequestFiles] ADD CONSTRAINT FK_SoapRequestFiles_Users_LastUpdatedBy 
    FOREIGN KEY ([LastUpdatedBy]) REFERENCES dbo.[Users]([UserId]);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapRequestFiles_OperationId' AND object_id = OBJECT_ID(N'dbo.SoapRequestFiles'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapRequestFiles_OperationId ON dbo.[SoapRequestFiles]([OperationId] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapRequestFiles_CreatedBy' AND object_id = OBJECT_ID(N'dbo.SoapRequestFiles'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapRequestFiles_CreatedBy ON dbo.[SoapRequestFiles]([CreatedBy] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapRequestFiles_IsActive' AND object_id = OBJECT_ID(N'dbo.SoapRequestFiles'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapRequestFiles_IsActive ON dbo.[SoapRequestFiles]([IsActive] ASC);
END
GO

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Saved test request template files.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapRequestFiles';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Primary key identifier.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapRequestFiles', @level2type=N'COLUMN',@level2name=N'Id';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Associated SOAP operation ID.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapRequestFiles', @level2type=N'COLUMN',@level2name=N'OperationId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Logical request file name.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapRequestFiles', @level2type=N'COLUMN',@level2name=N'FileName';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Compressed binary request payload.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapRequestFiles', @level2type=N'COLUMN',@level2name=N'FileData';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Uncompressed file byte count.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapRequestFiles', @level2type=N'COLUMN',@level2name=N'UncompressedSizeBytes';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'SHA-256 hash.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapRequestFiles', @level2type=N'COLUMN',@level2name=N'FileHash';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Request template version.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapRequestFiles', @level2type=N'COLUMN',@level2name=N'Version';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Active flag.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapRequestFiles', @level2type=N'COLUMN',@level2name=N'IsActive';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Creation timestamp.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapRequestFiles', @level2type=N'COLUMN',@level2name=N'CreatedAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Creator user.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapRequestFiles', @level2type=N'COLUMN',@level2name=N'CreatedBy';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Last updated timestamp.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapRequestFiles', @level2type=N'COLUMN',@level2name=N'LastUpdatedAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Modifier user.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapRequestFiles', @level2type=N'COLUMN',@level2name=N'LastUpdatedBy';
GO

-- ==========================================
-- 12. Create SoapRequestFileHistory Table
-- Logic Note: Retains differential or full snapshot revisions of SoapRequestFiles.
-- Controlled by ConstantSetting 'RequestFileDiffCount'.
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

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapRequestFileHistory_RequestFileId' AND object_id = OBJECT_ID(N'dbo.SoapRequestFileHistory'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapRequestFileHistory_RequestFileId ON dbo.[SoapRequestFileHistory]([RequestFileId] ASC);
END
GO

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Historical differential revisions of request files.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapRequestFileHistory';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Primary key identifier.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapRequestFileHistory', @level2type=N'COLUMN',@level2name=N'Id';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Parent request file ID.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapRequestFileHistory', @level2type=N'COLUMN',@level2name=N'RequestFileId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'History version tag.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapRequestFileHistory', @level2type=N'COLUMN',@level2name=N'Version';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Full snapshot payload binary (populated periodically).', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapRequestFileHistory', @level2type=N'COLUMN',@level2name=N'FileData';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Delta patch payload binary relative to prior revision.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapRequestFileHistory', @level2type=N'COLUMN',@level2name=N'DiffData';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Uncompressed payload byte count.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapRequestFileHistory', @level2type=N'COLUMN',@level2name=N'UncompressedSizeBytes';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'SHA-256 hash.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapRequestFileHistory', @level2type=N'COLUMN',@level2name=N'FileHash';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Creation timestamp.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapRequestFileHistory', @level2type=N'COLUMN',@level2name=N'CreatedAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Creator user.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapRequestFileHistory', @level2type=N'COLUMN',@level2name=N'CreatedBy';
GO

-- ==========================================
-- 13. Create SoapExecutionGroups Table
-- Logic Note: Groups single or multi-application requests into executable batch suites.
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

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapExecutionGroups_Users_LastUpdatedBy')
BEGIN
    ALTER TABLE dbo.[SoapExecutionGroups] ADD CONSTRAINT FK_SoapExecutionGroups_Users_LastUpdatedBy 
    FOREIGN KEY ([LastUpdatedBy]) REFERENCES dbo.[Users]([UserId]);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapExecutionGroups_AppId' AND object_id = OBJECT_ID(N'dbo.SoapExecutionGroups'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapExecutionGroups_AppId ON dbo.[SoapExecutionGroups]([AppId] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapExecutionGroups_IsActive' AND object_id = OBJECT_ID(N'dbo.SoapExecutionGroups'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapExecutionGroups_IsActive ON dbo.[SoapExecutionGroups]([IsActive] ASC);
END
GO

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Execution suites grouping multiple requests together.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionGroups';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Primary key identifier.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionGroups', @level2type=N'COLUMN',@level2name=N'Id';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Optional single application scope binding.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionGroups', @level2type=N'COLUMN',@level2name=N'AppId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Execution group name.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionGroups', @level2type=N'COLUMN',@level2name=N'GroupName';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Suite description.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionGroups', @level2type=N'COLUMN',@level2name=N'Description';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Active flag.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionGroups', @level2type=N'COLUMN',@level2name=N'IsActive';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Created timestamp.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionGroups', @level2type=N'COLUMN',@level2name=N'CreatedAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Creator user.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionGroups', @level2type=N'COLUMN',@level2name=N'CreatedBy';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Last updated timestamp.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionGroups', @level2type=N'COLUMN',@level2name=N'LastUpdatedAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Modifier user.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionGroups', @level2type=N'COLUMN',@level2name=N'LastUpdatedBy';
GO

-- ==========================================
-- 14. Create SoapExecutionGroupItems Table
-- Logic Note: Ordered items mapping request files (or specific historical request versions) to a group.
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

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapExecutionGroupItems_GroupId' AND object_id = OBJECT_ID(N'dbo.SoapExecutionGroupItems'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapExecutionGroupItems_GroupId ON dbo.[SoapExecutionGroupItems]([ExecutionGroupId] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapExecutionGroupItems_HistoryId' AND object_id = OBJECT_ID(N'dbo.SoapExecutionGroupItems'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapExecutionGroupItems_HistoryId ON dbo.[SoapExecutionGroupItems]([RequestFileHistoryId] ASC);
END
GO

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Ordered mapping table of request files included inside execution groups.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionGroupItems';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Primary key identifier.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionGroupItems', @level2type=N'COLUMN',@level2name=N'Id';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Parent execution group ID.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionGroupItems', @level2type=N'COLUMN',@level2name=N'ExecutionGroupId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Target request file ID.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionGroupItems', @level2type=N'COLUMN',@level2name=N'RequestFileId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Optional specific historical request file revision ID.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionGroupItems', @level2type=N'COLUMN',@level2name=N'RequestFileHistoryId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Sequential execution order index.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionGroupItems', @level2type=N'COLUMN',@level2name=N'ExecutionOrder';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Created timestamp.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionGroupItems', @level2type=N'COLUMN',@level2name=N'CreatedAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Creator user.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionGroupItems', @level2type=N'COLUMN',@level2name=N'CreatedBy';
GO

-- ==========================================
-- 15. Create SoapExecutionRuns Table
-- Logic Note: Logs top-level batch execution jobs. Includes CancelledAt tracking.
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

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapExecutionRuns_GroupId' AND object_id = OBJECT_ID(N'dbo.SoapExecutionRuns'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapExecutionRuns_GroupId ON dbo.[SoapExecutionRuns]([ExecutionGroupId] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapExecutionRuns_RunStatus' AND object_id = OBJECT_ID(N'dbo.SoapExecutionRuns'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapExecutionRuns_RunStatus ON dbo.[SoapExecutionRuns]([RunStatus] ASC);
END
GO

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Parent execution run instance for group batch executions.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionRuns';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Primary key identifier.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionRuns', @level2type=N'COLUMN',@level2name=N'Id';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Target execution group ID.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionRuns', @level2type=N'COLUMN',@level2name=N'ExecutionGroupId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Batch state: Pending, InProgress, Completed, Failed, Cancelled.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionRuns', @level2type=N'COLUMN',@level2name=N'RunStatus';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'User triggering execution.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionRuns', @level2type=N'COLUMN',@level2name=N'ExecutedBy';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Timestamp when execution batch started.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionRuns', @level2type=N'COLUMN',@level2name=N'StartedAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Completion timestamp.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionRuns', @level2type=N'COLUMN',@level2name=N'CompletedAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Cancellation timestamp if user aborted run.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionRuns', @level2type=N'COLUMN',@level2name=N'CancelledAt';
GO

-- ==========================================
-- 16. Create SoapExecutionItemRuns Table
-- Logic Note: Logs granular execution of each individual request inside a run. Includes CancelledAt.
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

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapExecutionItemRuns_RunId' AND object_id = OBJECT_ID(N'dbo.SoapExecutionItemRuns'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapExecutionItemRuns_RunId ON dbo.[SoapExecutionItemRuns]([ExecutionRunId] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapExecutionItemRuns_GroupItemId' AND object_id = OBJECT_ID(N'dbo.SoapExecutionItemRuns'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapExecutionItemRuns_GroupItemId ON dbo.[SoapExecutionItemRuns]([ExecutionGroupItemId] ASC);
END
GO

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Individual item execution telemetry within a run instance.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionItemRuns';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Primary key identifier.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionItemRuns', @level2type=N'COLUMN',@level2name=N'Id';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Parent batch run ID.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionItemRuns', @level2type=N'COLUMN',@level2name=N'ExecutionRunId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Associated group item mapping ID.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionItemRuns', @level2type=N'COLUMN',@level2name=N'ExecutionGroupItemId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Item execution state: Pending, InProgress, Success, Failure, Skipped, Cancelled.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionItemRuns', @level2type=N'COLUMN',@level2name=N'ItemExecutionStatus';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Execution start timestamp.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionItemRuns', @level2type=N'COLUMN',@level2name=N'ExecutedAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'User who initiated execution.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionItemRuns', @level2type=N'COLUMN',@level2name=N'ExecutedBy';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'HTTP response code returned from target service.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionItemRuns', @level2type=N'COLUMN',@level2name=N'HttpStatusCode';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Roundtrip network latency in milliseconds.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionItemRuns', @level2type=N'COLUMN',@level2name=N'ExecutionTimeMs';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Cancellation timestamp if item was aborted.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionItemRuns', @level2type=N'COLUMN',@level2name=N'CancelledAt';
GO

-- ==========================================
-- 17. Create SoapResponseFiles Table
-- Logic Note: Stores response content returned from SOAP operation calls.
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

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapResponseFiles_ExecutionItemRunId' AND object_id = OBJECT_ID(N'dbo.SoapResponseFiles'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapResponseFiles_ExecutionItemRunId ON dbo.[SoapResponseFiles]([ExecutionItemRunId] ASC);
END
GO

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'HTTP response payloads returned from operation calls.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapResponseFiles';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Primary key identifier.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapResponseFiles', @level2type=N'COLUMN',@level2name=N'Id';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Associated item execution ID.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapResponseFiles', @level2type=N'COLUMN',@level2name=N'ExecutionItemRunId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Format of returned response (XML, JSON, PDF, BINARY).', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapResponseFiles', @level2type=N'COLUMN',@level2name=N'ResponseFormat';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Compressed response payload binary.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapResponseFiles', @level2type=N'COLUMN',@level2name=N'FileData';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Uncompressed byte size.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapResponseFiles', @level2type=N'COLUMN',@level2name=N'UncompressedSizeBytes';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'SHA-256 hash.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapResponseFiles', @level2type=N'COLUMN',@level2name=N'FileHash';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Response snapshot version.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapResponseFiles', @level2type=N'COLUMN',@level2name=N'Version';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Creation timestamp.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapResponseFiles', @level2type=N'COLUMN',@level2name=N'CreatedAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Creator user.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapResponseFiles', @level2type=N'COLUMN',@level2name=N'CreatedBy';
GO

-- ==========================================
-- 18. Create SoapResponseEmbeddings Table
-- Logic Note: Extracted MIME/MTOM attachments returned within SOAP response messages.
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

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapResponseEmbeddings_ResponseFileId' AND object_id = OBJECT_ID(N'dbo.SoapResponseEmbeddings'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapResponseEmbeddings_ResponseFileId ON dbo.[SoapResponseEmbeddings]([ResponseFileId] ASC);
END
GO

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Binary attachments and embedded documents parsed from SOAP response streams.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapResponseEmbeddings';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Primary key identifier.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapResponseEmbeddings', @level2type=N'COLUMN',@level2name=N'Id';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Parent SOAP response file ID.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapResponseEmbeddings', @level2type=N'COLUMN',@level2name=N'ResponseFileId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Filename of attachment.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapResponseEmbeddings', @level2type=N'COLUMN',@level2name=N'AttachmentName';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'MIME content type (e.g. application/pdf, image/png).', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapResponseEmbeddings', @level2type=N'COLUMN',@level2name=N'ContentType';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Attachment binary data.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapResponseEmbeddings', @level2type=N'COLUMN',@level2name=N'FileData';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Uncompressed file byte count.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapResponseEmbeddings', @level2type=N'COLUMN',@level2name=N'UncompressedSizeBytes';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'SHA-256 hash.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapResponseEmbeddings', @level2type=N'COLUMN',@level2name=N'FileHash';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Creation timestamp.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapResponseEmbeddings', @level2type=N'COLUMN',@level2name=N'CreatedAt';
GO

-- ==========================================
-- 19. Create SoapResponseFileHistory Table
-- Logic Note: Audit and delta revisions of response structures over time.
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

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapResponseFileHistory_ResponseFileId' AND object_id = OBJECT_ID(N'dbo.SoapResponseFileHistory'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapResponseFileHistory_ResponseFileId ON dbo.[SoapResponseFileHistory]([ResponseFileId] ASC);
END
GO

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Historical differential revisions of response files.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapResponseFileHistory';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Primary key identifier.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapResponseFileHistory', @level2type=N'COLUMN',@level2name=N'Id';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Parent response file ID.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapResponseFileHistory', @level2type=N'COLUMN',@level2name=N'ResponseFileId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Revision version string.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapResponseFileHistory', @level2type=N'COLUMN',@level2name=N'Version';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Base snapshot binary.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapResponseFileHistory', @level2type=N'COLUMN',@level2name=N'FileData';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Differential delta patch binary.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapResponseFileHistory', @level2type=N'COLUMN',@level2name=N'DiffData';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Uncompressed file byte count.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapResponseFileHistory', @level2type=N'COLUMN',@level2name=N'UncompressedSizeBytes';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'SHA-256 hash.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapResponseFileHistory', @level2type=N'COLUMN',@level2name=N'FileHash';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Creation timestamp.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapResponseFileHistory', @level2type=N'COLUMN',@level2name=N'CreatedAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Creator user.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapResponseFileHistory', @level2type=N'COLUMN',@level2name=N'CreatedBy';
GO

-- ==========================================
-- 20. Create SoapOperationSchemas Table
-- Logic Note: XML XSD schema validation definitions. No CASCADE on OperationId to prevent SQL Error 1785.
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

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapOperationSchemas_WsdlSyncId' AND object_id = OBJECT_ID(N'dbo.SoapOperationSchemas'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapOperationSchemas_WsdlSyncId ON dbo.[SoapOperationSchemas]([WsdlSyncId] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapOperationSchemas_OperationId' AND object_id = OBJECT_ID(N'dbo.SoapOperationSchemas'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapOperationSchemas_OperationId ON dbo.[SoapOperationSchemas]([OperationId] ASC);
END
GO

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'XSD schema definitions associated with WSDL sync and operations.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapOperationSchemas';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Primary key identifier.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapOperationSchemas', @level2type=N'COLUMN',@level2name=N'Id';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Parent WSDL sync ID.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapOperationSchemas', @level2type=N'COLUMN',@level2name=N'WsdlSyncId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Optional specific SOAP operation ID.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapOperationSchemas', @level2type=N'COLUMN',@level2name=N'OperationId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Target XML namespace URI.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapOperationSchemas', @level2type=N'COLUMN',@level2name=N'TargetNamespace';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'XSD document payload content.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapOperationSchemas', @level2type=N'COLUMN',@level2name=N'XsdContent';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Creation timestamp.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapOperationSchemas', @level2type=N'COLUMN',@level2name=N'CreatedAt';
GO

-- ==========================================
-- 21. Create SoapNamespaces Table
-- Logic Note: Namespace prefix lookups for SOAP operations. No CASCADE on OperationId to prevent SQL Error 1785.
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

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapNamespaces_WsdlSyncId' AND object_id = OBJECT_ID(N'dbo.SoapNamespaces'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapNamespaces_WsdlSyncId ON dbo.[SoapNamespaces]([WsdlSyncId] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapNamespaces_OperationId' AND object_id = OBJECT_ID(N'dbo.SoapNamespaces'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapNamespaces_OperationId ON dbo.[SoapNamespaces]([OperationId] ASC);
END
GO

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'XML Namespace prefix mappings extracted during WSDL parsing.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapNamespaces';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Primary key identifier.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapNamespaces', @level2type=N'COLUMN',@level2name=N'Id';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Parent WSDL sync ID.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapNamespaces', @level2type=N'COLUMN',@level2name=N'WsdlSyncId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Optional specific SOAP operation ID.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapNamespaces', @level2type=N'COLUMN',@level2name=N'OperationId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Namespace XML prefix alias.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapNamespaces', @level2type=N'COLUMN',@level2name=N'Prefix';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Full Namespace URI.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapNamespaces', @level2type=N'COLUMN',@level2name=N'NamespaceUri';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Creation timestamp.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapNamespaces', @level2type=N'COLUMN',@level2name=N'CreatedAt';
GO

-- ==========================================
-- 22. Create SoapAppPermissions Table
-- Logic Note: Cascading root access boundary (Application level).
-- Application permissions must exist prior to sharing nested Request Files or Groups.
-- ==========================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'SoapAppPermissions' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[SoapAppPermissions] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [AppId] INT NOT NULL,
        [SharedWithUserId] NVARCHAR(20) NOT NULL,
        [AccessLevel] VARCHAR(20) NOT NULL CONSTRAINT DF_SoapAppPermissions_AccessLevel DEFAULT 'Read',
        [GrantedAt] DATETIME NOT NULL CONSTRAINT DF_SoapAppPermissions_GrantedAt DEFAULT GETDATE(),
        [GrantedBy] NVARCHAR(20) NOT NULL,

        CONSTRAINT PK_SoapAppPermissions PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT UQ_SoapAppPermissions UNIQUE ([AppId] ASC, [SharedWithUserId] ASC),
        CONSTRAINT CK_SoapAppPermissions_AccessLevel CHECK ([AccessLevel] IN ('Read', 'Write'))
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapAppPermissions_SoapApplications_AppId')
BEGIN
    ALTER TABLE dbo.[SoapAppPermissions] ADD CONSTRAINT FK_SoapAppPermissions_SoapApplications_AppId 
    FOREIGN KEY ([AppId]) REFERENCES dbo.[SoapApplications]([Id]) ON DELETE CASCADE;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapAppPermissions_Users_SharedWithUserId')
BEGIN
    ALTER TABLE dbo.[SoapAppPermissions] ADD CONSTRAINT FK_SoapAppPermissions_Users_SharedWithUserId 
    FOREIGN KEY ([SharedWithUserId]) REFERENCES dbo.[Users]([UserId]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapAppPermissions_Users_GrantedBy')
BEGIN
    ALTER TABLE dbo.[SoapAppPermissions] ADD CONSTRAINT FK_SoapAppPermissions_Users_GrantedBy 
    FOREIGN KEY ([GrantedBy]) REFERENCES dbo.[Users]([UserId]);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapAppPermissions_AppId' AND object_id = OBJECT_ID(N'dbo.SoapAppPermissions'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapAppPermissions_AppId ON dbo.[SoapAppPermissions]([AppId] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapAppPermissions_SharedWithUserId' AND object_id = OBJECT_ID(N'dbo.SoapAppPermissions'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapAppPermissions_SharedWithUserId ON dbo.[SoapAppPermissions]([SharedWithUserId] ASC);
END
GO

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Root level security permissions for entire application scopes.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapAppPermissions';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Primary key identifier.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapAppPermissions', @level2type=N'COLUMN',@level2name=N'Id';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Target application ID.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapAppPermissions', @level2type=N'COLUMN',@level2name=N'AppId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'User receiving access grant.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapAppPermissions', @level2type=N'COLUMN',@level2name=N'SharedWithUserId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Granted access level (Read, Write).', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapAppPermissions', @level2type=N'COLUMN',@level2name=N'AccessLevel';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Grant timestamp.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapAppPermissions', @level2type=N'COLUMN',@level2name=N'GrantedAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'User who issued access grant.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapAppPermissions', @level2type=N'COLUMN',@level2name=N'GrantedBy';
GO

-- ==========================================
-- 23. Create SoapRequestFilePermissions Table
-- Logic Note: Granular permission sharing for specific request files.
-- Shared request file permissions inherit constraints from root application access.
-- ==========================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'SoapRequestFilePermissions' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[SoapRequestFilePermissions] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [RequestFileId] INT NOT NULL,
        [SharedWithUserId] NVARCHAR(20) NOT NULL,
        [AccessLevel] VARCHAR(20) NOT NULL CONSTRAINT DF_SoapRequestFilePermissions_AccessLevel DEFAULT 'Read',
        [GrantedAt] DATETIME NOT NULL CONSTRAINT DF_SoapRequestFilePermissions_GrantedAt DEFAULT GETDATE(),
        [GrantedBy] NVARCHAR(20) NOT NULL,

        CONSTRAINT PK_SoapRequestFilePermissions PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT UQ_SoapRequestFilePermissions UNIQUE ([RequestFileId] ASC, [SharedWithUserId] ASC),
        CONSTRAINT CK_SoapRequestFilePermissions_AccessLevel CHECK ([AccessLevel] IN ('Read', 'Execute', 'Write'))
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapRequestFilePermissions_SoapRequestFiles_RequestFileId')
BEGIN
    ALTER TABLE dbo.[SoapRequestFilePermissions] ADD CONSTRAINT FK_SoapRequestFilePermissions_SoapRequestFiles_RequestFileId 
    FOREIGN KEY ([RequestFileId]) REFERENCES dbo.[SoapRequestFiles]([Id]) ON DELETE CASCADE;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapRequestFilePermissions_Users_SharedWithUserId')
BEGIN
    ALTER TABLE dbo.[SoapRequestFilePermissions] ADD CONSTRAINT FK_SoapRequestFilePermissions_Users_SharedWithUserId 
    FOREIGN KEY ([SharedWithUserId]) REFERENCES dbo.[Users]([UserId]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapRequestFilePermissions_Users_GrantedBy')
BEGIN
    ALTER TABLE dbo.[SoapRequestFilePermissions] ADD CONSTRAINT FK_SoapRequestFilePermissions_Users_GrantedBy 
    FOREIGN KEY ([GrantedBy]) REFERENCES dbo.[Users]([UserId]);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapRequestFilePermissions_RequestFileId' AND object_id = OBJECT_ID(N'dbo.SoapRequestFilePermissions'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapRequestFilePermissions_RequestFileId ON dbo.[SoapRequestFilePermissions]([RequestFileId] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapRequestFilePermissions_SharedWithUserId' AND object_id = OBJECT_ID(N'dbo.SoapRequestFilePermissions'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapRequestFilePermissions_SharedWithUserId ON dbo.[SoapRequestFilePermissions]([SharedWithUserId] ASC);
END
GO

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Granular security sharing permissions for individual request files.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapRequestFilePermissions';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Primary key identifier.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapRequestFilePermissions', @level2type=N'COLUMN',@level2name=N'Id';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Target request file ID.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapRequestFilePermissions', @level2type=N'COLUMN',@level2name=N'RequestFileId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'User receiving share.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapRequestFilePermissions', @level2type=N'COLUMN',@level2name=N'SharedWithUserId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Granted permission type (Read, Execute, Write).', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapRequestFilePermissions', @level2type=N'COLUMN',@level2name=N'AccessLevel';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Grant timestamp.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapRequestFilePermissions', @level2type=N'COLUMN',@level2name=N'GrantedAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'User issuing share grant.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapRequestFilePermissions', @level2type=N'COLUMN',@level2name=N'GrantedBy';
GO

-- ==========================================
-- 24. Create SoapExecutionGroupPermissions Table
-- Logic Note: Permissions for execution groups. Groups containing requests across multi-apps
-- can only be shared if all underlying target applications are also shared with the recipient.
-- ==========================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'SoapExecutionGroupPermissions' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[SoapExecutionGroupPermissions] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [ExecutionGroupId] INT NOT NULL,
        [SharedWithUserId] NVARCHAR(20) NOT NULL,
        [AccessLevel] VARCHAR(20) NOT NULL CONSTRAINT DF_SoapExecutionGroupPermissions_AccessLevel DEFAULT 'Read',
        [GrantedAt] DATETIME NOT NULL CONSTRAINT DF_SoapExecutionGroupPermissions_GrantedAt DEFAULT GETDATE(),
        [GrantedBy] NVARCHAR(20) NOT NULL,

        CONSTRAINT PK_SoapExecutionGroupPermissions PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT UQ_SoapExecutionGroupPermissions UNIQUE ([ExecutionGroupId] ASC, [SharedWithUserId] ASC),
        CONSTRAINT CK_SoapExecutionGroupPermissions_AccessLevel CHECK ([AccessLevel] IN ('Read', 'Execute', 'Write'))
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapExecutionGroupPermissions_SoapExecutionGroups_GroupId')
BEGIN
    ALTER TABLE dbo.[SoapExecutionGroupPermissions] ADD CONSTRAINT FK_SoapExecutionGroupPermissions_SoapExecutionGroups_GroupId 
    FOREIGN KEY ([ExecutionGroupId]) REFERENCES dbo.[SoapExecutionGroups]([Id]) ON DELETE CASCADE;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapExecutionGroupPermissions_Users_SharedWithUserId')
BEGIN
    ALTER TABLE dbo.[SoapExecutionGroupPermissions] ADD CONSTRAINT FK_SoapExecutionGroupPermissions_Users_SharedWithUserId 
    FOREIGN KEY ([SharedWithUserId]) REFERENCES dbo.[Users]([UserId]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapExecutionGroupPermissions_Users_GrantedBy')
BEGIN
    ALTER TABLE dbo.[SoapExecutionGroupPermissions] ADD CONSTRAINT FK_SoapExecutionGroupPermissions_Users_GrantedBy 
    FOREIGN KEY ([GrantedBy]) REFERENCES dbo.[Users]([UserId]);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapExecutionGroupPermissions_GroupId' AND object_id = OBJECT_ID(N'dbo.SoapExecutionGroupPermissions'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapExecutionGroupPermissions_GroupId ON dbo.[SoapExecutionGroupPermissions]([ExecutionGroupId] ASC);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_SoapExecutionGroupPermissions_SharedWithUserId' AND object_id = OBJECT_ID(N'dbo.SoapExecutionGroupPermissions'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_SoapExecutionGroupPermissions_SharedWithUserId ON dbo.[SoapExecutionGroupPermissions]([SharedWithUserId] ASC);
END
GO

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Access control and sharing permissions for execution groups.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionGroupPermissions';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Primary key identifier.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionGroupPermissions', @level2type=N'COLUMN',@level2name=N'Id';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Target execution group ID.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionGroupPermissions', @level2type=N'COLUMN',@level2name=N'ExecutionGroupId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'User receiving access grant.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionGroupPermissions', @level2type=N'COLUMN',@level2name=N'SharedWithUserId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Permission level (Read, Execute, Write).', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionGroupPermissions', @level2type=N'COLUMN',@level2name=N'AccessLevel';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Grant timestamp.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionGroupPermissions', @level2type=N'COLUMN',@level2name=N'GrantedAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'User issuing access grant.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SoapExecutionGroupPermissions', @level2type=N'COLUMN',@level2name=N'GrantedBy';
GO

-- ==========================================
-- 25. Create TestSuites Table
-- Logic Note: Automation testing suites bundling automated test cases.
-- ==========================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'TestSuites' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[TestSuites] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [SuiteName] NVARCHAR(200) NOT NULL,
        [Description] NVARCHAR(MAX) NULL,
        [IsActive] BIT NOT NULL CONSTRAINT DF_TestSuites_IsActive DEFAULT 1,
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_TestSuites_CreatedAt DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL,

        CONSTRAINT PK_TestSuites PRIMARY KEY CLUSTERED ([Id] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_TestSuites_Users_CreatedBy')
BEGIN
    ALTER TABLE dbo.[TestSuites] ADD CONSTRAINT FK_TestSuites_Users_CreatedBy 
    FOREIGN KEY ([CreatedBy]) REFERENCES dbo.[Users]([UserId]);
END
GO

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Test suite collections for functional service testing.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TestSuites';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Primary key identifier.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TestSuites', @level2type=N'COLUMN',@level2name=N'Id';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Name of test suite.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TestSuites', @level2type=N'COLUMN',@level2name=N'SuiteName';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Description of test suite scope.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TestSuites', @level2type=N'COLUMN',@level2name=N'Description';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Active flag.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TestSuites', @level2type=N'COLUMN',@level2name=N'IsActive';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Creation timestamp.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TestSuites', @level2type=N'COLUMN',@level2name=N'CreatedAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Creator user.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TestSuites', @level2type=N'COLUMN',@level2name=N'CreatedBy';
GO

-- ==========================================
-- 26. Create TestCases Table
-- Logic Note: Individual test case linked to a specific request file.
-- ==========================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'TestCases' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[TestCases] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [TestSuiteId] INT NOT NULL,
        [RequestFileId] INT NOT NULL,
        [TestCaseName] NVARCHAR(200) NOT NULL,
        [Description] NVARCHAR(MAX) NULL,
        [ExpectedResponseFormat] VARCHAR(10) NULL,
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_TestCases_CreatedAt DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL,

        CONSTRAINT PK_TestCases PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT CK_TestCases_Format CHECK ([ExpectedResponseFormat] IS NULL OR [ExpectedResponseFormat] IN ('XML','JSON','PDF'))
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_TestCases_TestSuites_TestSuiteId')
BEGIN
    ALTER TABLE dbo.[TestCases] ADD CONSTRAINT FK_TestCases_TestSuites_TestSuiteId 
    FOREIGN KEY ([TestSuiteId]) REFERENCES dbo.[TestSuites]([Id]) ON DELETE CASCADE;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_TestCases_SoapRequestFiles_RequestFileId')
BEGIN
    ALTER TABLE dbo.[TestCases] ADD CONSTRAINT FK_TestCases_SoapRequestFiles_RequestFileId 
    FOREIGN KEY ([RequestFileId]) REFERENCES dbo.[SoapRequestFiles]([Id]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_TestCases_Users_CreatedBy')
BEGIN
    ALTER TABLE dbo.[TestCases] ADD CONSTRAINT FK_TestCases_Users_CreatedBy 
    FOREIGN KEY ([CreatedBy]) REFERENCES dbo.[Users]([UserId]);
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_TestCases_TestSuiteId' AND object_id = OBJECT_ID(N'dbo.TestCases'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_TestCases_TestSuiteId ON dbo.[TestCases]([TestSuiteId] ASC);
END
GO

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Test cases defining functional validation specifications.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TestCases';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Primary key identifier.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TestCases', @level2type=N'COLUMN',@level2name=N'Id';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Parent test suite ID.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TestCases', @level2type=N'COLUMN',@level2name=N'TestSuiteId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Target request file ID.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TestCases', @level2type=N'COLUMN',@level2name=N'RequestFileId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Test case name.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TestCases', @level2type=N'COLUMN',@level2name=N'TestCaseName';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Test case description.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TestCases', @level2type=N'COLUMN',@level2name=N'Description';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Expected format of returned response.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TestCases', @level2type=N'COLUMN',@level2name=N'ExpectedResponseFormat';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Creation timestamp.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TestCases', @level2type=N'COLUMN',@level2name=N'CreatedAt';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Creator user.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TestCases', @level2type=N'COLUMN',@level2name=N'CreatedBy';
GO

-- ==========================================
-- 27. Create TestCaseValidationRules Table
-- Logic Note: Granular assertions (XPath, JSONPath, Regular Expression) evaluated against response contents.
-- ==========================================
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'TestCaseValidationRules' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[TestCaseValidationRules] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [TestCaseId] INT NOT NULL,
        [RuleType] NVARCHAR(50) NOT NULL,
        [TargetExpression] NVARCHAR(MAX) NOT NULL,
        [ExpectedValue] NVARCHAR(MAX) NOT NULL,
        [IsActive] BIT NOT NULL CONSTRAINT DF_TestCaseValidationRules_IsActive DEFAULT 1,

        CONSTRAINT PK_TestCaseValidationRules PRIMARY KEY CLUSTERED ([Id] ASC)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_TestCaseValidationRules_TestCases_TestCaseId')
BEGIN
    ALTER TABLE dbo.[TestCaseValidationRules] ADD CONSTRAINT FK_TestCaseValidationRules_TestCases_TestCaseId 
    FOREIGN KEY ([TestCaseId]) REFERENCES dbo.[TestCases]([Id]) ON DELETE CASCADE;
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = N'IX_TestCaseValidationRules_TestCaseId' AND object_id = OBJECT_ID(N'dbo.TestCaseValidationRules'))
BEGIN
    CREATE NONCLUSTERED INDEX IX_TestCaseValidationRules_TestCaseId ON dbo.[TestCaseValidationRules]([TestCaseId] ASC);
END
GO

EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Assertion rules evaluated against test case responses.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TestCaseValidationRules';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Primary key identifier.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TestCaseValidationRules', @level2type=N'COLUMN',@level2name=N'Id';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Parent test case ID.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TestCaseValidationRules', @level2type=N'COLUMN',@level2name=N'TestCaseId';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Rule type (e.g. XPathEquals, ContainsText, JsonPathEquals, ResponseHeader).', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TestCaseValidationRules', @level2type=N'COLUMN',@level2name=N'RuleType';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Target evaluation path expression.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TestCaseValidationRules', @level2type=N'COLUMN',@level2name=N'TargetExpression';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Expected value assertion payload.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TestCaseValidationRules', @level2type=N'COLUMN',@level2name=N'ExpectedValue';
EXEC sp_addextendedproperty @name=N'MS_Description', @value=N'Active flag.', @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'TestCaseValidationRules', @level2type=N'COLUMN',@level2name=N'IsActive';
GO