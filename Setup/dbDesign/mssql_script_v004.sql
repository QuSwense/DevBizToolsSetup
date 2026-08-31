-- ==========================================
-- Create Database if not exists
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
-- Configuration Parameters
-- ==========================================
-- Set to 1 to DROP all existing tables/objects and recreate from scratch.
-- Set to 0 to safely preserve existing tables/objects and only create missing ones.
DECLARE @DropExistingObjects BIT = 1;

IF @DropExistingObjects = 1
BEGIN
    -- Drop Foreign Key constraints that cause circular dependencies or teardown issues
    IF EXISTS (SELECT * FROM [sys].[foreign_keys] WHERE [name] = N'FK_SoapAppAuthentication_SoapApplications')
        ALTER TABLE [SoapAppAuthentication] DROP CONSTRAINT [FK_SoapAppAuthentication_SoapApplications];

    -- Drop tables in reverse-dependency order
    IF OBJECT_ID(N'[TestCaseValidationRules]', N'U') IS NOT NULL DROP TABLE [TestCaseValidationRules];
    IF OBJECT_ID(N'[TestCases]', N'U') IS NOT NULL DROP TABLE [TestCases];
    IF OBJECT_ID(N'[TestSuites]', N'U') IS NOT NULL DROP TABLE [TestSuites];
    IF OBJECT_ID(N'[SoapUpdateHistory]', N'U') IS NOT NULL DROP TABLE [SoapUpdateHistory];
    IF OBJECT_ID(N'[SoapWsdlSync]', N'U') IS NOT NULL DROP TABLE [SoapWsdlSync];
    IF OBJECT_ID(N'[SoapResponseFileHistory]', N'U') IS NOT NULL DROP TABLE [SoapResponseFileHistory];
    IF OBJECT_ID(N'[SoapResponseAttachments]', N'U') IS NOT NULL DROP TABLE [SoapResponseAttachments];
    IF OBJECT_ID(N'[SoapResponseFiles]', N'U') IS NOT NULL DROP TABLE [SoapResponseFiles];
    IF OBJECT_ID(N'[SoapExecutionItemRuns]', N'U') IS NOT NULL DROP TABLE [SoapExecutionItemRuns];
    IF OBJECT_ID(N'[SoapExecutionRuns]', N'U') IS NOT NULL DROP TABLE [SoapExecutionRuns];
    IF OBJECT_ID(N'[SoapExecutionGroupItems]', N'U') IS NOT NULL DROP TABLE [SoapExecutionGroupItems];
    IF OBJECT_ID(N'[SoapExecutionGroupsPermissions]', N'U') IS NOT NULL DROP TABLE [SoapExecutionGroupsPermissions];
    IF OBJECT_ID(N'[SoapExecutionGroups]', N'U') IS NOT NULL DROP TABLE [SoapExecutionGroups];
    IF OBJECT_ID(N'[SoapRequestFileHistory]', N'U') IS NOT NULL DROP TABLE [SoapRequestFileHistory];
    IF OBJECT_ID(N'[SoapRequestFilePermissions]', N'U') IS NOT NULL DROP TABLE [SoapRequestFilePermissions];
    IF OBJECT_ID(N'[SoapRequestFiles]', N'U') IS NOT NULL DROP TABLE [SoapRequestFiles];
    IF OBJECT_ID(N'[SoapOperations]', N'U') IS NOT NULL DROP TABLE [SoapOperations];
    IF OBJECT_ID(N'[SoapAppPermissions]', N'U') IS NOT NULL DROP TABLE [SoapAppPermissions];
    IF OBJECT_ID(N'[SoapApplications]', N'U') IS NOT NULL DROP TABLE [SoapApplications];
    IF OBJECT_ID(N'[SoapAppAuthentication]', N'U') IS NOT NULL DROP TABLE [SoapAppAuthentication];
    IF OBJECT_ID(N'[ConstantSettings]', N'U') IS NOT NULL DROP TABLE [ConstantSettings];
    IF OBJECT_ID(N'[EntityChangeHistory]', N'U') IS NOT NULL DROP TABLE [EntityChangeHistory];
    IF OBJECT_ID(N'[UserActivities]', N'U') IS NOT NULL DROP TABLE [UserActivities];
    IF OBJECT_ID(N'[Users]', N'U') IS NOT NULL DROP TABLE [Users];
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
            'Team Leader', 'Project Manager', 'Business', 'Management'
        )),
        [IsActive] BIT NOT NULL DEFAULT 1,
        [CreatedBy] NVARCHAR(20) NOT NULL,
        [CreatedDate] DATETIME NOT NULL DEFAULT GETDATE(),
        [UpdatedDate] DATETIME NULL
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
        [ActivityId] BIGINT IDENTITY(1,1) PRIMARY KEY,
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
        [SettingKey] NVARCHAR(100) NOT NULL UNIQUE,
        [SettingValue] NVARCHAR(MAX) NOT NULL,
        [Description] NVARCHAR(500) NULL,
        [IsActive] BIT NOT NULL DEFAULT 1
    );
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
-- Create SoapAppAuthentication Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM [sys].[tables] 
    WHERE [name] = N'SoapAppAuthentication'
)
BEGIN
    CREATE TABLE [SoapAppAuthentication] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [AppId] INT NOT NULL, -- FK added after SoapApplications creation to prevent circular dependency
        [AuthenticationType] VARCHAR(50) NOT NULL CHECK ([AuthenticationType] IN ('Basic', 'NTLM', 'APIKey', 'OAuth2')),
        [EncryptedCredentialsJson] NVARCHAR(MAX) NOT NULL, -- Encrypted JSON payload containing credentials
        [IsActive] BIT NOT NULL DEFAULT 1,
        [CreatedAt] DATETIME NOT NULL DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES [Users]([UserId]),
        [LastUpdatedAt] DATETIME NULL,
        [LastUpdatedBy] NVARCHAR(20) NULL FOREIGN KEY REFERENCES [Users]([UserId])
    );
END
GO

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_SoapAppAuthentication_AppId' AND [object_id] = OBJECT_ID(N'[SoapAppAuthentication]'))
BEGIN
    CREATE INDEX [IX_SoapAppAuthentication_AppId] ON [SoapAppAuthentication]([AppId]);
END
GO

-- ==========================================
-- Create SoapApplications Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM [sys].[tables] 
    WHERE [name] = N'SoapApplications'
)
BEGIN
    CREATE TABLE [SoapApplications] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [AppName] NVARCHAR(200) UNIQUE NOT NULL,
        [BaseUrl] NVARCHAR(500) NOT NULL,
        [WsdlRelativeUrl] NVARCHAR(250) NULL,
        [HealthcheckRelativeUrl] NVARCHAR(250) NULL,
        [Description] NVARCHAR(MAX) NULL,
        [SoapAppAuthenticationId] INT NULL FOREIGN KEY REFERENCES [SoapAppAuthentication]([Id]),
        [IsActive] BIT NOT NULL DEFAULT 1,
        [Version] VARCHAR(50) NOT NULL, -- YY.QQ.FullFileDataIncrement.DiffIncrement
        [CreatedAt] DATETIME NOT NULL DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES [Users]([UserId]),
        [LastUpdatedAt] DATETIME NULL,
        [LastUpdatedBy] NVARCHAR(20) NULL FOREIGN KEY REFERENCES [Users]([UserId])
    );
END
GO

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_SoapApplications_AppName' AND [object_id] = OBJECT_ID(N'[SoapApplications]'))
BEGIN
    CREATE INDEX [IX_SoapApplications_AppName] ON [SoapApplications]([AppName]);
END
GO

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_SoapApplications_CreatedBy' AND [object_id] = OBJECT_ID(N'[SoapApplications]'))
BEGIN
    CREATE INDEX [IX_SoapApplications_CreatedBy] ON [SoapApplications]([CreatedBy]);
END
GO

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_SoapApplications_AuthId' AND [object_id] = OBJECT_ID(N'[SoapApplications]'))
BEGIN
    CREATE INDEX [IX_SoapApplications_AuthId] ON [SoapApplications]([SoapAppAuthenticationId]);
END
GO

-- Add FK for SoapAppAuthentication -> SoapApplications
IF NOT EXISTS (
    SELECT * FROM [sys].[foreign_keys] WHERE [name] = 'FK_SoapAppAuthentication_SoapApplications'
)
BEGIN
    ALTER TABLE [SoapAppAuthentication]
    ADD CONSTRAINT [FK_SoapAppAuthentication_SoapApplications] 
    FOREIGN KEY ([AppId]) REFERENCES [SoapApplications]([Id]) ON DELETE CASCADE;
END
GO

-- ==========================================
-- Create SoapAppPermissions Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM [sys].[tables] 
    WHERE [name] = N'SoapAppPermissions'
)
BEGIN
    CREATE TABLE [SoapAppPermissions] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [AppId] INT NOT NULL FOREIGN KEY REFERENCES [SoapApplications]([Id]) ON DELETE CASCADE,
        [SharedWithUserId] NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES [Users]([UserId]),
        [AccessLevel] VARCHAR(20) NOT NULL DEFAULT 'Read' CHECK ([AccessLevel] IN ('Read', 'Write')), -- Write includes Read
        [GrantedAt] DATETIME NOT NULL DEFAULT GETDATE(),
        [GrantedBy] NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES [Users]([UserId]),
        CONSTRAINT [UQ_SoapAppPermissions] UNIQUE ([AppId], [SharedWithUserId])
    );
END
GO

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_SoapAppPermissions_AppId' AND [object_id] = OBJECT_ID(N'[SoapAppPermissions]'))
BEGIN
    CREATE INDEX [IX_SoapAppPermissions_AppId] ON [SoapAppPermissions]([AppId]);
END
GO

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_SoapAppPermissions_SharedWithUserId' AND [object_id] = OBJECT_ID(N'[SoapAppPermissions]'))
BEGIN
    CREATE INDEX [IX_SoapAppPermissions_SharedWithUserId] ON [SoapAppPermissions]([SharedWithUserId]);
END
GO

-- ==========================================
-- Create SoapOperations Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM [sys].[tables] 
    WHERE [name] = N'SoapOperations'
)
BEGIN
    CREATE TABLE [SoapOperations] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [AppId] INT NOT NULL FOREIGN KEY REFERENCES [SoapApplications]([Id]) ON DELETE CASCADE,
        [OperationName] NVARCHAR(200) NOT NULL,
        [Description] NVARCHAR(MAX) NULL,
        [SoapAction] NVARCHAR(200) NULL
    );
END
GO

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_SoapOperations_AppId' AND [object_id] = OBJECT_ID(N'[SoapOperations]'))
BEGIN
    CREATE INDEX [IX_SoapOperations_AppId] ON [SoapOperations]([AppId]);
END
GO

-- ==========================================
-- Create SoapRequestFiles Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM [sys].[tables] 
    WHERE [name] = N'SoapRequestFiles'
)
BEGIN
    CREATE TABLE [SoapRequestFiles] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [OperationId] INT NOT NULL FOREIGN KEY REFERENCES [SoapOperations]([Id]) ON DELETE CASCADE,
        [FileName] NVARCHAR(250) NOT NULL,
        [FileData] VARBINARY(MAX) NOT NULL, -- Always stores full raw payload
        [UncompressedSizeBytes] INT NULL,
        [FileHash] VARCHAR(64) NULL,               -- SHA-256 integrity hash
        [Version] VARCHAR(50) NOT NULL,            -- YY.QQ.FullFileDataIncrement.DiffIncrement
        [CreatedAt] DATETIME NOT NULL DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES [Users]([UserId]),
        [LastUpdatedAt] DATETIME NULL,
        [LastUpdatedBy] NVARCHAR(20) NULL FOREIGN KEY REFERENCES [Users]([UserId])
    );
END
GO

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_SoapRequestFiles_OperationId' AND [object_id] = OBJECT_ID(N'[SoapRequestFiles]'))
BEGIN
    CREATE INDEX [IX_SoapRequestFiles_OperationId] ON [SoapRequestFiles]([OperationId]);
END
GO

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_SoapRequestFiles_CreatedBy' AND [object_id] = OBJECT_ID(N'[SoapRequestFiles]'))
BEGIN
    CREATE INDEX [IX_SoapRequestFiles_CreatedBy] ON [SoapRequestFiles]([CreatedBy]);
END
GO

-- ==========================================
-- Create SoapRequestFilePermissions Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM [sys].[tables] 
    WHERE [name] = N'SoapRequestFilePermissions'
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

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_SoapRequestFilePermissions_RequestFileId' AND [object_id] = OBJECT_ID(N'[SoapRequestFilePermissions]'))
BEGIN
    CREATE INDEX [IX_SoapRequestFilePermissions_RequestFileId] ON [SoapRequestFilePermissions]([RequestFileId]);
END
GO

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_SoapRequestFilePermissions_SharedWithUserId' AND [object_id] = OBJECT_ID(N'[SoapRequestFilePermissions]'))
BEGIN
    CREATE INDEX [IX_SoapRequestFilePermissions_SharedWithUserId] ON [SoapRequestFilePermissions]([SharedWithUserId]);
END
GO

-- ==========================================
-- Create SoapRequestFileHistory Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM [sys].[tables] 
    WHERE [name] = N'SoapRequestFileHistory'
)
BEGIN
    CREATE TABLE [SoapRequestFileHistory] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [RequestFileId] INT NOT NULL FOREIGN KEY REFERENCES [SoapRequestFiles]([Id]) ON DELETE CASCADE,
        [Version] VARCHAR(50) NOT NULL,            -- YY.QQ.FullFileDataIncrement.DiffIncrement
        [FileData] VARBINARY(MAX) NULL,            -- Full base payload when DiffIncrement = 00
        [DiffData] VARBINARY(MAX) NULL,            -- Delta patch payload when DiffIncrement <= RequestFileDiffCount (e.g. <= 5)
        [UncompressedSizeBytes] INT NULL,
        [FileHash] VARCHAR(64) NULL,
        [CreatedAt] DATETIME NOT NULL DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES [Users]([UserId])
    );
END
GO

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_SoapRequestFileHistory_RequestFileId' AND [object_id] = OBJECT_ID(N'[SoapRequestFileHistory]'))
BEGIN
    CREATE INDEX [IX_SoapRequestFileHistory_RequestFileId] ON [SoapRequestFileHistory]([RequestFileId]);
END
GO

-- ==========================================
-- Create SoapExecutionGroups Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM [sys].[tables] 
    WHERE [name] = N'SoapExecutionGroups'
)
BEGIN
    CREATE TABLE [SoapExecutionGroups] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [AppId] INT NULL FOREIGN KEY REFERENCES [SoapApplications]([Id]), -- Optional: Can be NULL if mixing multiple apps
        [GroupName] NVARCHAR(200) NOT NULL,
        [Description] NVARCHAR(MAX) NULL,
        [IsActive] BIT NOT NULL DEFAULT 1,
        [CreatedAt] DATETIME NOT NULL DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES [Users]([UserId]),
        [LastUpdatedAt] DATETIME NULL,
        [LastUpdatedBy] NVARCHAR(20) NULL FOREIGN KEY REFERENCES [Users]([UserId])
    );
END
GO

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_SoapExecutionGroups_AppId' AND [object_id] = OBJECT_ID(N'[SoapExecutionGroups]'))
BEGIN
    CREATE INDEX [IX_SoapExecutionGroups_AppId] ON [SoapExecutionGroups]([AppId]);
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

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_SoapExecutionGroupsPermissions_GroupId' AND [object_id] = OBJECT_ID(N'[SoapExecutionGroupsPermissions]'))
BEGIN
    CREATE INDEX [IX_SoapExecutionGroupsPermissions_GroupId] ON [SoapExecutionGroupsPermissions]([ExecutionGroupId]);
END
GO

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_SoapExecutionGroupsPermissions_SharedWithUserId' AND [object_id] = OBJECT_ID(N'[SoapExecutionGroupsPermissions]'))
BEGIN
    CREATE INDEX [IX_SoapExecutionGroupsPermissions_SharedWithUserId] ON [SoapExecutionGroupsPermissions]([SharedWithUserId]);
END
GO

-- ==========================================
-- Create SoapExecutionGroupItems Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM [sys].[tables] 
    WHERE [name] = N'SoapExecutionGroupItems'
)
BEGIN
    CREATE TABLE [SoapExecutionGroupItems] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [ExecutionGroupId] INT NOT NULL FOREIGN KEY REFERENCES [SoapExecutionGroups]([Id]) ON DELETE CASCADE,
        [RequestFileId] INT NOT NULL FOREIGN KEY REFERENCES [SoapRequestFiles]([Id]),
        [ExecutionOrder] INT NOT NULL DEFAULT 1,
        [CreatedAt] DATETIME NOT NULL DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES [Users]([UserId])
    );
END
GO

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_SoapExecutionGroupItems_GroupId' AND [object_id] = OBJECT_ID(N'[SoapExecutionGroupItems]'))
BEGIN
    CREATE INDEX [IX_SoapExecutionGroupItems_GroupId] ON [SoapExecutionGroupItems]([ExecutionGroupId]);
END
GO

-- ==========================================
-- Create SoapExecutionRuns Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM [sys].[tables] 
    WHERE [name] = N'SoapExecutionRuns'
)
BEGIN
    CREATE TABLE [SoapExecutionRuns] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [ExecutionGroupId] INT NOT NULL FOREIGN KEY REFERENCES [SoapExecutionGroups]([Id]) ON DELETE CASCADE,
        [RunStatus] VARCHAR(20) NOT NULL DEFAULT 'Pending' 
            CHECK ([RunStatus] IN ('Pending', 'InProgress', 'Completed', 'Failed', 'Cancelled')),
        [ExecutedBy] NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES [Users]([UserId]),
        [StartedAt] DATETIME NOT NULL DEFAULT GETDATE(),
        [CompletedAt] DATETIME NULL
    );
END
GO

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_SoapExecutionRuns_GroupId' AND [object_id] = OBJECT_ID(N'[SoapExecutionRuns]'))
BEGIN
    CREATE INDEX [IX_SoapExecutionRuns_GroupId] ON [SoapExecutionRuns]([ExecutionGroupId]);
END
GO

-- ==========================================
-- Create SoapExecutionItemRuns Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM [sys].[tables] 
    WHERE [name] = N'SoapExecutionItemRuns'
)
BEGIN
    CREATE TABLE [SoapExecutionItemRuns] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [ExecutionRunId] INT NOT NULL FOREIGN KEY REFERENCES [SoapExecutionRuns]([Id]) ON DELETE CASCADE,
        [ExecutionGroupItemId] INT NOT NULL FOREIGN KEY REFERENCES [SoapExecutionGroupItems]([Id]),
        [ItemExecutionStatus] VARCHAR(20) NOT NULL DEFAULT 'Pending' 
            CHECK ([ItemExecutionStatus] IN ('Pending', 'InProgress', 'Success', 'Failure', 'Skipped')),
        [ExecutedAt] DATETIME NOT NULL DEFAULT GETDATE(),
        [ExecutedBy] NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES [Users]([UserId]),
        [HttpStatusCode] INT NULL,
        [ExecutionTimeMs] INT NULL
    );
END
GO

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_SoapExecutionItemRuns_RunId' AND [object_id] = OBJECT_ID(N'[SoapExecutionItemRuns]'))
BEGIN
    CREATE INDEX [IX_SoapExecutionItemRuns_RunId] ON [SoapExecutionItemRuns]([ExecutionRunId]);
END
GO

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_SoapExecutionItemRuns_GroupItemId' AND [object_id] = OBJECT_ID(N'[SoapExecutionItemRuns]'))
BEGIN
    CREATE INDEX [IX_SoapExecutionItemRuns_GroupItemId] ON [SoapExecutionItemRuns]([ExecutionGroupItemId]);
END
GO

-- ==========================================
-- Create SoapResponseFiles Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM [sys].[tables] 
    WHERE [name] = N'SoapResponseFiles'
)
BEGIN
    CREATE TABLE [SoapResponseFiles] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [ExecutionItemRunId] INT NOT NULL FOREIGN KEY REFERENCES [SoapExecutionItemRuns]([Id]) ON DELETE CASCADE,
        [ResponseFormat] VARCHAR(10) CHECK ([ResponseFormat] IN ('XML','JSON','PDF','BINARY')),
        [FileData] VARBINARY(MAX) NOT NULL,       -- Main response payload (compressed/encrypted in C#)
        [UncompressedSizeBytes] INT NULL,
        [FileHash] VARCHAR(64) NULL,               -- SHA-256 hash
        [Version] VARCHAR(50) NOT NULL,            -- YY.QQ.FullFileDataIncrement.DiffIncrement
        [CreatedAt] DATETIME NOT NULL DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES [Users]([UserId])
    );
END
GO

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_SoapResponseFiles_ExecutionItemRunId' AND [object_id] = OBJECT_ID(N'[SoapResponseFiles]'))
BEGIN
    CREATE INDEX [IX_SoapResponseFiles_ExecutionItemRunId] ON [SoapResponseFiles]([ExecutionItemRunId]);
END
GO

-- ==========================================
-- Create SoapResponseAttachments Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM [sys].[tables] 
    WHERE [name] = N'SoapResponseAttachments'
)
BEGIN
    CREATE TABLE [SoapResponseAttachments] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [ResponseFileId] INT NOT NULL FOREIGN KEY REFERENCES [SoapResponseFiles]([Id]) ON DELETE CASCADE,
        [AttachmentName] NVARCHAR(250) NOT NULL,
        [ContentType] NVARCHAR(100) NOT NULL,      -- e.g. 'application/pdf', 'image/png', 'text/xml'
        [FileData] VARBINARY(MAX) NOT NULL,       -- Compressed & Encrypted binary data
        [UncompressedSizeBytes] INT NULL,
        [FileHash] VARCHAR(64) NULL,
        [CreatedAt] DATETIME NOT NULL DEFAULT GETDATE()
    );
END
GO

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_SoapResponseAttachments_ResponseFileId' AND [object_id] = OBJECT_ID(N'[SoapResponseAttachments]'))
BEGIN
    CREATE INDEX [IX_SoapResponseAttachments_ResponseFileId] ON [SoapResponseAttachments]([ResponseFileId]);
END
GO

-- ==========================================
-- Create SoapResponseFileHistory Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM [sys].[tables] 
    WHERE [name] = N'SoapResponseFileHistory'
)
BEGIN
    CREATE TABLE [SoapResponseFileHistory] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [ResponseFileId] INT NOT NULL FOREIGN KEY REFERENCES [SoapResponseFiles]([Id]) ON DELETE CASCADE,
        [Version] VARCHAR(50) NOT NULL,            -- YY.QQ.FullFileDataIncrement.DiffIncrement
        [FileData] VARBINARY(MAX) NULL,            -- Full base response payload when DiffIncrement = 00
        [DiffData] VARBINARY(MAX) NULL,            -- Delta patch payload when DiffIncrement <= RequestFileDiffCount (e.g. <= 5)
        [UncompressedSizeBytes] INT NULL,
        [FileHash] VARCHAR(64) NULL,
        [CreatedAt] DATETIME NOT NULL DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES [Users]([UserId])
    );
END
GO

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_SoapResponseFileHistory_ResponseFileId' AND [object_id] = OBJECT_ID(N'[SoapResponseFileHistory]'))
BEGIN
    CREATE INDEX [IX_SoapResponseFileHistory_ResponseFileId] ON [SoapResponseFileHistory]([ResponseFileId]);
END
GO

-- ==========================================
-- Create SoapWsdlSync Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM [sys].[tables] 
    WHERE [name] = N'SoapWsdlSync'
)
BEGIN
    CREATE TABLE [SoapWsdlSync] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [AppId] INT NOT NULL FOREIGN KEY REFERENCES [SoapApplications]([Id]) ON DELETE CASCADE,
        [WsdlUrl] NVARCHAR(500) NOT NULL,
        [SyncedAt] DATETIME NOT NULL DEFAULT GETDATE(),
        [SyncedBy] NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES [Users]([UserId])
    );
END
GO

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_SoapWsdlSync_AppId' AND [object_id] = OBJECT_ID(N'[SoapWsdlSync]'))
BEGIN
    CREATE INDEX [IX_SoapWsdlSync_AppId] ON [SoapWsdlSync]([AppId]);
END
GO

-- ==========================================
-- Create SoapUpdateHistory Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM [sys].[tables] 
    WHERE [name] = N'SoapUpdateHistory'
)
BEGIN
    CREATE TABLE [SoapUpdateHistory] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [AppId] INT NOT NULL FOREIGN KEY REFERENCES [SoapApplications]([Id]) ON DELETE CASCADE,
        [UpdatedAt] DATETIME NOT NULL DEFAULT GETDATE(),
        [UpdatedBy] NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES [Users]([UserId]),
        [SystemLog] NVARCHAR(MAX) NOT NULL,
        [Comment] NVARCHAR(MAX) NULL
    );
END
GO

IF NOT EXISTS (SELECT * FROM [sys].[indexes] WHERE [name] = N'IX_SoapUpdateHistory_AppId' AND [object_id] = OBJECT_ID(N'[SoapUpdateHistory]'))
BEGIN
    CREATE INDEX [IX_SoapUpdateHistory_AppId] ON [SoapUpdateHistory]([AppId]);
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