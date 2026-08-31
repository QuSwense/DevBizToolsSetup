/*
    Table: RuleSets
    Description: Stores the rule sets for workflows, including their JSON definitions and metadata.
    Logic: Each rule set is associated with a specific workflow based on MRE (Microsoft Rules Engine) and has an output type defined in the RuleContextObjects table. The RuleContent column must contain valid JSON, and the RecordVersion follows a specific format for versioning.
*/
CREATE TABLE [dbo].[RuleSets] (
    -- Primary Key and Identity
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Workflow and Rule Definition Name
    [WorkflowName] NVARCHAR(255) NOT NULL UNIQUE,
    -- JSON Rule Definition, only one rule set per workflow is allowed
    [RuleContent] NVARCHAR(MAX) NOT NULL,
    -- Output Type Reference, linking to RuleContextObjects
    [OutputTypeId] INT NOT NULL,
    -- Active Status of the Rule Set
    [IsActive] BIT DEFAULT 1,
    -- Optional Description of the Rule Set
    [Description] NVARCHAR(500) NULL,
    -- Versioning and Audit Fields
    [RecordVersion] VARCHAR(50) NOT NULL
        CONSTRAINT DF_RuleSets_RecordVersion DEFAULT ([dbo].[fn_CalculateVersion](NULL)),
    -- Timestamps for auditing created and last updated
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
