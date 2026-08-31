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
-- Create Users Table
-- ==========================================
IF NOT EXISTS (
    SELECT * 
    FROM [sysobjects] 
    WHERE [name] = 'Users' AND [xtype] = 'U'
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
    FROM [sysobjects] 
    WHERE [name] = 'UserActivities' AND [xtype] = 'U'
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

-- ==========================================
-- Create ConstantSettings Table
-- ==========================================
IF NOT EXISTS (
    SELECT * FROM [sysobjects] WHERE [name] = 'ConstantSettings' AND [xtype] = 'U'
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
    VALUES ('RequestFileDiffCount', '5', 'Number of request file diffs to retain in history before forcing a full base file version', 1);
END
GO

-- ==========================================
-- Create SoapAppAuthentication Table
-- ==========================================
IF NOT EXISTS (
    SELECT * FROM [sysobjects] WHERE [name] = 'SoapAppAuthentication' AND [xtype] = 'U'
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

-- ==========================================
-- Create SoapApplications Table
-- ==========================================
IF NOT EXISTS (
    SELECT * FROM [sysobjects] WHERE [name] = 'SoapApplications' AND [xtype] = 'U'
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
    SELECT * FROM [sysobjects] WHERE [name] = 'SoapAppPermissions' AND [xtype] = 'U'
)
BEGIN
    CREATE TABLE [SoapAppPermissions] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [AppId] INT NOT NULL FOREIGN KEY REFERENCES [SoapApplications]([Id]) ON DELETE CASCADE,
        [SharedWithUserId] NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES [Users]([UserId]),
        [AccessLevel] VARCHAR(20) NOT NULL DEFAULT 'Read' CHECK ([AccessLevel] IN ('Read', 'Write')),
        [GrantedAt] DATETIME NOT NULL DEFAULT GETDATE(),
        [GrantedBy] NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES [Users]([UserId]),
        CONSTRAINT [UQ_SoapAppPermissions] UNIQUE ([AppId], [SharedWithUserId])
    );
END
GO

-- ==========================================
-- Create SoapOperations Table
-- ==========================================
IF NOT EXISTS (
    SELECT * FROM [sysobjects] WHERE [name] = 'SoapOperations' AND [xtype] = 'U'
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

-- ==========================================
-- Create SoapRequestFiles Table
-- ==========================================
IF NOT EXISTS (
    SELECT * FROM [sysobjects] WHERE [name] = 'SoapRequestFiles' AND [xtype] = 'U'
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

-- ==========================================
-- Create SoapRequestFilePermissions Table
-- ==========================================
IF NOT EXISTS (
    SELECT * FROM [sysobjects] WHERE [name] = 'SoapRequestFilePermissions' AND [xtype] = 'U'
)
BEGIN
    CREATE TABLE [SoapRequestFilePermissions] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [RequestFileId] INT NOT NULL FOREIGN KEY REFERENCES [SoapRequestFiles]([Id]) ON DELETE CASCADE,
        [SharedWithUserId] NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES [Users]([UserId]),
        [AccessLevel] VARCHAR(20) NOT NULL DEFAULT 'Read' CHECK ([AccessLevel] IN ('Read', 'Execute', 'Write')),
        [GrantedAt] DATETIME NOT NULL DEFAULT GETDATE(),
        [GrantedBy] NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES [Users]([UserId]),
        CONSTRAINT [UQ_SoapRequestFilePermissions] UNIQUE ([RequestFileId], [SharedWithUserId])
    );
END
GO

-- ==========================================
-- Create SoapRequestFileHistory Table
-- ==========================================
IF NOT EXISTS (
    SELECT * FROM [sysobjects] WHERE [name] = 'SoapRequestFileHistory' AND [xtype] = 'U'
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

-- ==========================================
-- Update SoapExecutionGroups Table
-- Added Status tracking and Start/End audit timestamps
-- ==========================================
IF NOT EXISTS (
    SELECT * FROM [sysobjects] WHERE [name] = 'SoapExecutionGroups' AND [xtype] = 'U'
)
BEGIN
    CREATE TABLE [SoapExecutionGroups] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [AppId] INT NULL FOREIGN KEY REFERENCES [SoapApplications]([Id]), -- Optional: Can be NULL if mixing multiple apps in one group
        [GroupName] NVARCHAR(200) NOT NULL,
        [ExecutionStatus] VARCHAR(20) NOT NULL DEFAULT 'Pending' 
            CHECK ([ExecutionStatus] IN ('Pending', 'InProgress', 'Completed', 'Failed', 'Cancelled')),
        [TotalItemsCount] INT NOT NULL DEFAULT 0,
        [CreatedAt] DATETIME NOT NULL DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES [Users]([UserId]),
        [StartedAt] DATETIME NULL,
        [CompletedAt] DATETIME NULL,
        [LastUpdatedAt] DATETIME NULL,
        [LastUpdatedBy] NVARCHAR(20) NULL FOREIGN KEY REFERENCES [Users]([UserId])
    );
END
GO

-- ==========================================
-- Create SoapExecutionGroupItems Table (NEW)
-- Maps request files to an Execution Group & tracks per-item execution progress
-- ==========================================
IF NOT EXISTS (
    SELECT * FROM [sysobjects] WHERE [name] = 'SoapExecutionGroupItems' AND [xtype] = 'U'
)
BEGIN
    CREATE TABLE [SoapExecutionGroupItems] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [ExecutionGroupId] INT NOT NULL FOREIGN KEY REFERENCES [SoapExecutionGroups]([Id]) ON DELETE CASCADE,
        [RequestFileId] INT NOT NULL FOREIGN KEY REFERENCES [SoapRequestFiles]([Id]),
        [ExecutionOrder] INT NOT NULL DEFAULT 1,
        [ItemStatus] VARCHAR(20) NOT NULL DEFAULT 'Pending' 
            CHECK ([ItemStatus] IN ('Pending', 'InProgress', 'Passed', 'Failed', 'Skipped')),
        [StartedAt] DATETIME NULL,
        [CompletedAt] DATETIME NULL
    );
END
GO

-- ==========================================
-- Create SoapExecutionHistory Table
-- ==========================================
IF NOT EXISTS (
    SELECT * FROM [sysobjects] WHERE [name] = 'SoapExecutionHistory' AND [xtype] = 'U'
)
BEGIN
    CREATE TABLE [SoapExecutionHistory] (
        [Id] INT IDENTITY(1,1) PRIMARY KEY,
        [ExecutionGroupId] INT NOT NULL FOREIGN KEY REFERENCES [SoapExecutionGroups]([Id]) ON DELETE CASCADE,
        [RequestFileId] INT NOT NULL FOREIGN KEY REFERENCES [SoapRequestFiles]([Id]),
        [ExecutedAt] DATETIME NOT NULL DEFAULT GETDATE(),
        [ExecutedBy] NVARCHAR(20) NOT NULL FOREIGN KEY REFERENCES [Users]([UserId]),
        [ResponseFormat] VARCHAR(10) CHECK ([ResponseFormat] IN ('XML','JSON','PDF')),
        [ResponseContent] NVARCHAR(MAX) NULL,
        [ExecutionStatus] VARCHAR(20) CHECK ([ExecutionStatus] IN ('Success','Failure')) NOT NULL,
        [HttpStatusCode] INT NULL,
        [ExecutionTimeMs] INT NULL
    );
END
GO

-- ==========================================
-- Create SoapWsdlSync Table
-- ==========================================
IF NOT EXISTS (
    SELECT * FROM [sysobjects] WHERE [name] = 'SoapWsdlSync' AND [xtype] = 'U'
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

-- ==========================================
-- Create SoapUpdateHistory Table
-- ==========================================
IF NOT EXISTS (
    SELECT * FROM [sysobjects] WHERE [name] = 'SoapUpdateHistory' AND [xtype] = 'U'
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

-- ==========================================
-- Create TestSuites Table
-- ==========================================
IF NOT EXISTS (
    SELECT * FROM [sysobjects] WHERE [name] = 'TestSuites' AND [xtype] = 'U'
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
    SELECT * FROM [sysobjects] WHERE [name] = 'TestCases' AND [xtype] = 'U'
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

-- ==========================================
-- Create TestCaseValidationRules Table
-- ==========================================
IF NOT EXISTS (
    SELECT * FROM [sysobjects] WHERE [name] = 'TestCaseValidationRules' AND [xtype] = 'U'
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

-- ==========================================
-- Performance & Security Indexes
-- ==========================================
CREATE INDEX [IX_UserActivities_UserId] ON [UserActivities]([UserId]);
CREATE INDEX [IX_UserActivities_Timestamp] ON [UserActivities]([Timestamp]);
CREATE INDEX [IX_UserActivities_TableName_TableId] ON [UserActivities]([TableName], [TableId]);
CREATE INDEX [IX_SoapApplications_AppName] ON [SoapApplications]([AppName]);
CREATE INDEX [IX_SoapApplications_CreatedBy] ON [SoapApplications]([CreatedBy]);
CREATE INDEX [IX_SoapApplications_AuthId] ON [SoapApplications]([SoapAppAuthenticationId]);
CREATE INDEX [IX_SoapAppPermissions_AppId] ON [SoapAppPermissions]([AppId]);
CREATE INDEX [IX_SoapAppPermissions_SharedWithUserId] ON [SoapAppPermissions]([SharedWithUserId]);
CREATE INDEX [IX_SoapAppAuthentication_AppId] ON [SoapAppAuthentication]([AppId]);
CREATE INDEX [IX_SoapOperations_AppId] ON [SoapOperations]([AppId]);
CREATE INDEX [IX_SoapRequestFiles_OperationId] ON [SoapRequestFiles]([OperationId]);
CREATE INDEX [IX_SoapRequestFiles_CreatedBy] ON [SoapRequestFiles]([CreatedBy]);
CREATE INDEX [IX_SoapRequestFilePermissions_RequestFileId] ON [SoapRequestFilePermissions]([RequestFileId]);
CREATE INDEX [IX_SoapRequestFilePermissions_SharedWithUserId] ON [SoapRequestFilePermissions]([SharedWithUserId]);
CREATE INDEX [IX_SoapRequestFileHistory_RequestFileId] ON [SoapRequestFileHistory]([RequestFileId]);
CREATE INDEX [IX_SoapExecutionGroups_AppId] ON [SoapExecutionGroups]([AppId]);
CREATE INDEX [IX_SoapExecutionGroupItems_GroupId] ON [SoapExecutionGroupItems]([ExecutionGroupId]);
CREATE INDEX [IX_SoapExecutionGroupItems_Status] ON [SoapExecutionGroupItems]([ExecutionGroupId], [ItemStatus]);
CREATE INDEX [IX_SoapExecutionHistory_GroupId] ON [SoapExecutionHistory]([ExecutionGroupId]);
CREATE INDEX [IX_SoapExecutionHistory_RequestFileId] ON [SoapExecutionHistory]([RequestFileId]);
CREATE INDEX [IX_SoapWsdlSync_AppId] ON [SoapWsdlSync]([AppId]);
CREATE INDEX [IX_SoapUpdateHistory_AppId] ON [SoapUpdateHistory]([AppId]);
CREATE INDEX [IX_TestCases_TestSuiteId] ON [TestCases]([TestSuiteId]);
CREATE INDEX [IX_TestCaseValidationRules_TestCaseId] ON [TestCaseValidationRules]([TestCaseId]);
GO