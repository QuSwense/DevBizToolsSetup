CREATE TABLE [dbo].[RuleSets] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [WorkflowName] NVARCHAR(255) NOT NULL UNIQUE,
    [RuleContent] NVARCHAR(MAX) NOT NULL,         -- JSON rule definition
    [OutputTypeId] INT NOT NULL,
    [IsActive] BIT DEFAULT 1,
    [Description] NVARCHAR(500) NULL,
    [RecordVersion] VARCHAR(50) NOT NULL
        CONSTRAINT DF_RuleSets_RecordVersion DEFAULT ([dbo].[fn_CalculateVersion](NULL)),
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
        REFERENCES [dbo].[RuleContextObjects]([Id]),
    CONSTRAINT FK_RuleSets_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_RuleSets_Users_LastUpdatedBy
        FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
)
