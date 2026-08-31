-- ==========================================
-- Test Suites, Test Cases & Execution Groups
-- ==========================================
USE [OrbitTool];
GO

-- ServiceTestCases Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'ServiceTestCases' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[ServiceTestCases] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [Name] NVARCHAR(200) NOT NULL,
        [ServiceRequestFileId] INT NOT NULL,
        [IsActive] BIT NOT NULL CONSTRAINT DF_ServiceTestCases_IsActive DEFAULT 1,
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceTestCases_CreatedAt DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL,
        [LastUpdatedAt] DATETIME NULL,
        [LastUpdatedBy] NVARCHAR(20) NULL,

        -- Primary Key
        CONSTRAINT PK_ServiceTestCases PRIMARY KEY CLUSTERED ([Id] ASC),
        
        -- Foreign Key
        CONSTRAINT FK_ServiceTestCases_Users_CreatedBy 
            FOREIGN KEY ([CreatedBy]) REFERENCES dbo.[Users]([UserId]),
        CONSTRAINT FK_ServiceTestCases_Users_LastUpdatedBy 
            FOREIGN KEY ([LastUpdatedBy]) REFERENCES dbo.[Users]([UserId])
    );
END
GO

-- ServiceTestCaseRuleSetLinks Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'ServiceTestCaseRuleSetLinks' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[ServiceTestCaseRuleSetLinks] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [ServiceTestCaseId] INT NOT NULL,
        [RuleSetId] INT NOT NULL,
        [IsActive] BIT NOT NULL CONSTRAINT DF_ServiceTestCaseRuleSetLinks_IsActive DEFAULT 1,
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceTestCaseRuleSetLinks_CreatedAt DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL,

        -- Primary Key
        CONSTRAINT PK_ServiceTestCaseRuleSetLinks PRIMARY KEY CLUSTERED ([Id] ASC),
        
        -- Foreign Key
        CONSTRAINT FK_ServiceTestCaseRuleSetLinks_ServiceTestCases_ServiceTestCaseId 
            FOREIGN KEY ([ServiceTestCaseId]) REFERENCES dbo.[ServiceTestCases]([Id]) ON DELETE CASCADE,
        CONSTRAINT FK_ServiceTestCaseRuleSetLinks_RuleSets_RuleSetId
            FOREIGN KEY ([RuleSetId]) REFERENCES dbo.[RuleSets]([Id]) ON DELETE CASCADE,
        CONSTRAINT FK_ServiceTestCaseRuleSetLinks_Users_CreatedBy 
            FOREIGN KEY ([CreatedBy]) REFERENCES dbo.[Users]([UserId])
    );
END
GO

-- ServiceTestSuites Table: Group related test cases
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'ServiceTestSuites' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[ServiceTestSuites] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [Name] NVARCHAR(200) NOT NULL,
        [Description] NVARCHAR(MAX) NULL,
        [ServiceApplicationId] INT NULL,  -- Optional: specific to a service
        [IsActive] BIT NOT NULL CONSTRAINT DF_ServiceTestSuites_IsActive DEFAULT 1,
        [RecordVersion] VARCHAR(50) NOT NULL 
            CONSTRAINT DF_ServiceTestSuites_RecordVersion DEFAULT (dbo.fn_CalculateVersion(NULL)),
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceTestSuites_CreatedAt DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL,
        [LastUpdatedAt] DATETIME NULL,
        [LastUpdatedBy] NVARCHAR(20) NULL,

        CONSTRAINT PK_ServiceTestSuites PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT UQ_ServiceTestSuites_Name UNIQUE ([Name] ASC),
        CONSTRAINT CK_ServiceTestSuites_RecordVersionFormat 
            CHECK ([RecordVersion] LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9]'),

        CONSTRAINT FK_ServiceTestSuites_ServiceApplications_ServiceApplicationId 
            FOREIGN KEY ([ServiceApplicationId]) REFERENCES dbo.[ServiceApplications]([Id]) ON DELETE SET NULL,
        CONSTRAINT FK_ServiceTestSuites_Users_CreatedBy 
            FOREIGN KEY ([CreatedBy]) REFERENCES dbo.[Users]([UserId]),
        CONSTRAINT FK_ServiceTestSuites_Users_LastUpdatedBy 
            FOREIGN KEY ([LastUpdatedBy]) REFERENCES dbo.[Users]([UserId])
    );
END
GO

-- 2. ServiceTestSuitTestCaseLinks Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'ServiceTestSuitTestCaseLinks' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[ServiceTestSuitTestCaseLinks] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [ServiceTestSuiteId] INT NOT NULL,
        [ServiceTestCaseId] INT NOT NULL,
        [ExecutionOrder] INT NOT NULL CONSTRAINT DF_TestCases_ExecutionOrder DEFAULT 1,
        [IsActive] BIT NOT NULL CONSTRAINT DF_TestCases_IsActive DEFAULT 1,
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_TestCases_CreatedAt DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL,

        CONSTRAINT PK_ServiceTestSuitTestCaseLinks PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT FK_ServiceTestSuitTestCaseLinks_ServiceTestSuites_ServiceTestSuiteId 
            FOREIGN KEY ([ServiceTestSuiteId]) REFERENCES dbo.[ServiceTestSuites]([Id]) ON DELETE CASCADE,
        CONSTRAINT FK_ServiceTestSuitTestCaseLinks_ServiceTestCases_ServiceTestCaseId 
            FOREIGN KEY ([ServiceTestCaseId]) REFERENCES dbo.[ServiceTestCases]([Id]) ON DELETE CASCADE,
        CONSTRAINT FK_ServiceTestSuitTestCaseLinks_Users_CreatedBy 
            FOREIGN KEY ([CreatedBy]) REFERENCES dbo.[Users]([UserId])
    );
END
GO

-- 4. ServiceTestExecutionAudits Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'ServiceTestExecutionAudits' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[ServiceTestExecutionAudits] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [ServiceTestSuiteId] INT NOT NULL,
        [ExecutedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceTestExecutionAudits_ExecutedAt DEFAULT GETDATE(),
        [ExecutionCompletedAt] DATETIME NULL,
        [ExecutionStatus] NVARCHAR(50) NOT NULL,
        [ExecutionDetails] NVARCHAR(MAX) NULL, -- JSON or text details about the execution
        [ExecutedBy] NVARCHAR(20) NOT NULL,

        CONSTRAINT PK_ServiceTestExecutionAudits PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT FK_ServiceTestExecutionAudits_ServiceTestSuites_ServiceTestSuiteId
            FOREIGN KEY ([ServiceTestSuiteId]) REFERENCES dbo.[ServiceTestSuites]([Id]) ON DELETE CASCADE,
        CONSTRAINT FK_ServiceTestExecutionAudits_Users_ExecutedBy
            FOREIGN KEY ([ExecutedBy]) REFERENCES dbo.[Users]([UserId])
    );
END
GO

-- DirectExecutionAuditResponseFileLinks Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'ServiceTestExecutionAuditTestSuitLinks' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[ServiceTestExecutionAuditTestSuitLinks] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [ServiceTestExecutionAuditId] INT NOT NULL,
        [ServiceTestCaseId] INT NOT NULL,
        [ServiceResponseFileId] INT NOT NULL,
        [ExecutedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceTestExecutionAuditTestSuitLinks_ExecutedAt DEFAULT GETDATE(),
        [ExecutionCompletedAt] DATETIME NULL,
        [HttpStatusCode] INT NULL, -- Response status code (200, 404, 500, etc.)
        [HttpVersion] NVARCHAR(10) NULL, -- HTTP/1.1, HTTP/2, HTTP/3
        [HttpRequestDurationMs] INT NULL, -- Total request duration in milliseconds
        [HttpRequestHeaders] NVARCHAR(MAX) NULL, -- JSON of request headers
        [HttpResponseHeaders] NVARCHAR(MAX) NULL, -- JSON of response headers
        [HttpContentType] NVARCHAR(255) NULL, -- Content-Type from response
        [HttpContentLength] BIGINT NULL, -- Response content length in bytes
        [ExecutionStatus] NVARCHAR(50) NOT NULL,
        [ExecutionDetails] NVARCHAR(MAX) NULL, -- JSON or text details about the execution like ErrorTYpe, ErrorMessage, StackTrace, etc.
        [ExecutedBy] NVARCHAR(20) NOT NULL,

        CONSTRAINT PK_ServiceTestExecutionAuditTestSuitLinks PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT FK_ServiceTestExecutionAuditTestSuitLinks_ServiceTestExecutionAudits_ServiceTestExecutionAuditId
            FOREIGN KEY ([ServiceTestExecutionAuditId]) REFERENCES dbo.[ServiceTestExecutionAudits]([Id]) ON DELETE CASCADE,
        CONSTRAINT FK_ServiceTestExecutionAuditTestSuitLinks_ServiceTestCases_ServiceTestCaseId
            FOREIGN KEY ([ServiceTestCaseId]) REFERENCES dbo.[ServiceTestCases]([Id]) ON DELETE CASCADE,
        CONSTRAINT FK_ServiceTestExecutionAuditTestSuitLinks_ServiceResponseFiles_ServiceResponseFileId
            FOREIGN KEY ([ServiceResponseFileId]) REFERENCES dbo.[ServiceResponseFiles]([Id]) ON DELETE CASCADE
    );
END
GO