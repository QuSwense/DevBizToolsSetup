
USE [ServiceHubDb];
GO

-- RuleContextObjects Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'RuleContextObjects' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[RuleContextObjects] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [ContextName] NVARCHAR(100) NOT NULL UNIQUE,  -- e.g., "Customer", "Order", "Product"
        [RuleTypeId] NVARCHAR(255) NOT NULL,         -- Full assembly-qualified type name
        [Description] NVARCHAR(500) NULL,
        [IsActive] BIT DEFAULT 1,
        [CreatedDate] DATETIME DEFAULT GETDATE(),

        CONSTRAINT PK_RuleContextObjects PRIMARY KEY CLUSTERED ([Id] ASC)
    );
END
GO

-- RuleSets Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'RuleSets' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[RuleSets] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [WorkflowName] NVARCHAR(255) NOT NULL UNIQUE,
        [RuleContent] NVARCHAR(MAX) NOT NULL,         -- JSON rule definition
        [OutputTypeId] INT NOT NULL,
        [IsActive] BIT DEFAULT 1,
        [Description] NVARCHAR(500) NULL,
        [RecordVersion] VARCHAR(50) NOT NULL 
            CONSTRAINT DF_RuleSets_RecordVersion DEFAULT (dbo.fn_CalculateVersion(NULL)),
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_RuleSets_CreatedAt DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL,
        [LastUpdatedAt] DATETIME NULL,
        [LastUpdatedBy] NVARCHAR(20) NULL,

        CONSTRAINT PK_RuleSets PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT UIX_RuleSets_WorkflowName UNIQUE ([WorkflowName] ASC),
        CONSTRAINT CK_RuleSets_RuleContentJson
            CHECK (ISJSON([RuleContent]) = 1),
        CONSTRAINT CK_RuleSets_RecordVersionFormat 
            CHECK ([RecordVersion] LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9]'),

        CONSTRAINT FK_RuleSets_RuleContextObjects FOREIGN KEY ([OutputTypeId]) 
            REFERENCES [dbo].[RuleContextObjects]([Id]) ON DELETE CASCADE,
        CONSTRAINT FK_RuleSets_Users_CreatedBy 
            FOREIGN KEY ([CreatedBy]) REFERENCES dbo.[Users]([UserId]),
        CONSTRAINT FK_RuleSets_Users_LastUpdatedBy 
            FOREIGN KEY ([LastUpdatedBy]) REFERENCES dbo.[Users]([UserId])
    );
END
GO

-- RuleSetContextObjectLinks Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'RuleSetContextObjectLinks' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[RuleSetContextObjectLinks] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [RuleSetId] INT NOT NULL,
        [RuleContextObjectId] INT NOT NULL,
        [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_RuleSetContextObjectLinks_CreatedAt DEFAULT GETDATE(),
        [CreatedBy] NVARCHAR(20) NOT NULL,
        [LastUpdatedAt] DATETIME NULL,
        [LastUpdatedBy] NVARCHAR(20) NULL,

        CONSTRAINT PK_RuleSetContextObjectLinks PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT FK_RuleSetContextObjectLinks_RuleSets FOREIGN KEY ([RuleSetId])
            REFERENCES dbo.[RuleSets]([Id]) ON DELETE CASCADE,
        CONSTRAINT FK_RuleSetContextObjectLinks_RuleContextObjects FOREIGN KEY ([RuleContextObjectId])
            REFERENCES dbo.[RuleContextObjects]([Id]) ON DELETE CASCADE
    );
END
GO

-- RuleExecutionLogs Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'RuleExecutionLogs' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[RuleExecutionLogs] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [RuleSetId] INT NOT NULL,
        [ContextSnapshot] NVARCHAR(MAX) NOT NULL, -- JSON of input objects
        [IsSuccess] BIT NOT NULL,
        [Result] NVARCHAR(MAX) NULL,                  -- JSON serialized output
        [ErrorMessage] NVARCHAR(MAX) NULL,
        [ExecutionTimeMs] INT NULL,
        [ExecutedAt] DATETIME NOT NULL CONSTRAINT DF_RuleExecutionLogs_ExecutedAt DEFAULT GETDATE(),
        [ExecutedBy] NVARCHAR(20) NOT NULL,

        CONSTRAINT PK_RuleExecutionLogs PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT CK_RuleExecutionLogs_ContextSnapshot
            CHECK (ISJSON([ContextSnapshot]) = 1),
        CONSTRAINT CK_RuleExecutionLogs_Result
            CHECK (ISJSON([Result]) = 1),

        CONSTRAINT FK_RuleExecutionLogs_RuleSets FOREIGN KEY ([RuleSetId])
            REFERENCES dbo.[RuleSets]([Id]) ON DELETE CASCADE,
        CONSTRAINT FK_RuleExecutionLogs_Users_ExecutedBy
            FOREIGN KEY ([ExecutedBy]) REFERENCES dbo.[Users]([UserId])
    );
END
GO