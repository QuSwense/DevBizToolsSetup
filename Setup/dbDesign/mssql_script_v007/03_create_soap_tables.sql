-- ============================================================================
-- SCRIPT 3: SOAP SPECIFIC TABLES
-- Target Engine: Microsoft SQL Server
-- Includes: PKs, FKs, Indexes, Constraints, and Extended Properties
-- ============================================================================

SET NOCOUNT ON;

-- 1. SOAP APPLICATIONS TABLE
CREATE TABLE dbo.SoapApplications (
    SoapAppId INT IDENTITY(1,1) NOT NULL,
    AppName NVARCHAR(100) NOT NULL,
    WsdlUrl NVARCHAR(500) NULL,
    Description NVARCHAR(500) NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_SoapApplications_IsActive DEFAULT (1),
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_SoapApplications_CreatedAt DEFAULT (SYSDATETIME()),
    UpdatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_SoapApplications PRIMARY KEY CLUSTERED (SoapAppId ASC),
    CONSTRAINT UQ_SoapApplications_AppName UNIQUE (AppName)
);

-- 2. SOAP APP AUTHENTICATION TABLE
CREATE TABLE dbo.SoapAppAuth (
    SoapAuthId INT IDENTITY(1,1) NOT NULL,
    SoapAppId INT NOT NULL,
    AuthType NVARCHAR(50) NOT NULL, -- e.g., Basic, WS-Security, Bearer
    Username NVARCHAR(100) NULL,
    PasswordHash NVARCHAR(500) NULL,
    AuthHeaderName NVARCHAR(100) NULL,
    AuthHeaderValue NVARCHAR(MAX) NULL,
    CONSTRAINT PK_SoapAppAuth PRIMARY KEY CLUSTERED (SoapAuthId ASC),
    CONSTRAINT FK_SoapAppAuth_SoapApplications FOREIGN KEY (SoapAppId) REFERENCES dbo.SoapApplications(SoapAppId) ON DELETE CASCADE
);

-- 3. SOAP OPERATIONS TABLE
CREATE TABLE dbo.SoapOperations (
    SoapOperationId INT IDENTITY(1,1) NOT NULL,
    SoapAppId INT NOT NULL,
    OperationName NVARCHAR(150) NOT NULL,
    SoapAction NVARCHAR(300) NULL,
    TargetNamespace NVARCHAR(300) NULL,
    RequestSampleXml NVARCHAR(MAX) NULL,
    CONSTRAINT PK_SoapOperations PRIMARY KEY CLUSTERED (SoapOperationId ASC),
    CONSTRAINT FK_SoapOperations_SoapApplications FOREIGN KEY (SoapAppId) REFERENCES dbo.SoapApplications(SoapAppId) ON DELETE CASCADE
);

-- 4. SOAP WSDL SYNC HISTORY
CREATE TABLE dbo.SoapWsdlSync (
    SyncId INT IDENTITY(1,1) NOT NULL,
    SoapAppId INT NOT NULL,
    SyncStatus NVARCHAR(50) NOT NULL,
    SyncDetails NVARCHAR(MAX) NULL,
    SyncedAt DATETIME2(7) NOT NULL CONSTRAINT DF_SoapWsdlSync_SyncedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_SoapWsdlSync PRIMARY KEY CLUSTERED (SyncId ASC),
    CONSTRAINT FK_SoapWsdlSync_SoapApplications FOREIGN KEY (SoapAppId) REFERENCES dbo.SoapApplications(SoapAppId) ON DELETE CASCADE
);

-- 5. SOAP REQUEST FILES TABLE
CREATE TABLE dbo.SoapRequestFiles (
    SoapRequestId INT IDENTITY(1,1) NOT NULL,
    SoapAppId INT NOT NULL,
    SoapOperationId INT NOT NULL,
    RequestName NVARCHAR(150) NOT NULL,
    PayloadXml NVARCHAR(MAX) NOT NULL,
    HeadersJson NVARCHAR(MAX) NULL,
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_SoapRequestFiles_CreatedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_SoapRequestFiles PRIMARY KEY CLUSTERED (SoapRequestId ASC),
    CONSTRAINT FK_SoapRequestFiles_SoapApplications FOREIGN KEY (SoapAppId) REFERENCES dbo.SoapApplications(SoapAppId),
    CONSTRAINT FK_SoapRequestFiles_SoapOperations FOREIGN KEY (SoapOperationId) REFERENCES dbo.SoapOperations(SoapOperationId)
);

-- 6. SOAP EXECUTION GROUPS (Embedded Application Test Suites)
CREATE TABLE dbo.SoapExecutionGroups (
    SoapExecutionGroupId INT IDENTITY(1,1) NOT NULL,
    SoapAppId INT NOT NULL,
    GroupName NVARCHAR(150) NOT NULL,
    Description NVARCHAR(255) NULL,
    ExecutionOrder INT NOT NULL CONSTRAINT DF_SoapExecutionGroups_ExecutionOrder DEFAULT (1),
    IsActive BIT NOT NULL CONSTRAINT DF_SoapExecutionGroups_IsActive DEFAULT (1),
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_SoapExecutionGroups_CreatedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_SoapExecutionGroups PRIMARY KEY CLUSTERED (SoapExecutionGroupId ASC),
    CONSTRAINT FK_SoapExecutionGroups_SoapApplications FOREIGN KEY (SoapAppId) REFERENCES dbo.SoapApplications(SoapAppId) ON DELETE CASCADE
);

-- 7. SOAP EXECUTION GROUP DETAILS
CREATE TABLE dbo.SoapExecutionGroupDetails (
    DetailId INT IDENTITY(1,1) NOT NULL,
    SoapExecutionGroupId INT NOT NULL,
    SoapRequestId INT NOT NULL,
    StepOrder INT NOT NULL,
    CONSTRAINT PK_SoapExecutionGroupDetails PRIMARY KEY CLUSTERED (DetailId ASC),
    CONSTRAINT FK_SoapExecutionGroupDetails_SoapExecutionGroups FOREIGN KEY (SoapExecutionGroupId) REFERENCES dbo.SoapExecutionGroups(SoapExecutionGroupId) ON DELETE CASCADE,
    CONSTRAINT FK_SoapExecutionGroupDetails_SoapRequestFiles FOREIGN KEY (SoapRequestId) REFERENCES dbo.SoapRequestFiles(SoapRequestId)
);

-- 8. SOAP RESPONSE FILES TABLE
CREATE TABLE dbo.SoapResponseFiles (
    SoapResponseId INT IDENTITY(1,1) NOT NULL,
    SoapRequestId INT NOT NULL,
    StatusCode INT NOT NULL,
    ResponseXml NVARCHAR(MAX) NULL,
    ExecutionTimeMs INT NOT NULL,
    ExecutedAt DATETIME2(7) NOT NULL CONSTRAINT DF_SoapResponseFiles_ExecutedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_SoapResponseFiles PRIMARY KEY CLUSTERED (SoapResponseId ASC),
    CONSTRAINT FK_SoapResponseFiles_SoapRequestFiles FOREIGN KEY (SoapRequestId) REFERENCES dbo.SoapRequestFiles(SoapRequestId) ON DELETE CASCADE
);

-- ----------------------------------------------------------------------------
-- INDEXES
-- ----------------------------------------------------------------------------
CREATE NONCLUSTERED INDEX IX_SoapOperations_SoapAppId ON dbo.SoapOperations(SoapAppId);
CREATE NONCLUSTERED INDEX IX_SoapRequestFiles_SoapAppId ON dbo.SoapRequestFiles(SoapAppId);
CREATE NONCLUSTERED INDEX IX_SoapRequestFiles_SoapOperationId ON dbo.SoapRequestFiles(SoapOperationId);
CREATE NONCLUSTERED INDEX IX_SoapExecutionGroups_SoapAppId ON dbo.SoapExecutionGroups(SoapAppId);

-- ----------------------------------------------------------------------------
-- EXTENDED PROPERTIES (DOCUMENTATION)
-- ----------------------------------------------------------------------------
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'SOAP Application master configuration.', @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'SoapApplications';
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Test suites / execution groups embedded strictly within SOAP applications.', @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'SoapExecutionGroups';
GO