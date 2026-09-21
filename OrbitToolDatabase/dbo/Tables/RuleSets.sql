/*
    Table: RuleSets
    Description: Stores the rule sets for workflows, including their JSON definitions and metadata.
    Logic: Each rule set is associated with a specific workflow based on MRE (Microsoft Rules Engine) and has an output type defined in the RuleContextObjects table. The RuleContent column must contain valid JSON, and the RecordVersion follows a specific format for versioning.
*/
CREATE TABLE [dbo].[RuleSets] (
    -- Primary Key and Identity
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Public Identifier for UI/Secure Operations (GUID)
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_RuleSets_PublicId DEFAULT NEWID(),
    -- Workflow and Rule Definition Name
    [WorkflowName] NVARCHAR(255) NOT NULL,
    -- JSON Rule Definition, 
    [RuleContent] NVARCHAR(MAX) NOT NULL,
    -- Output Type Reference, linking to RuleContextObjects
    [OutputDataTypeId] INT NOT NULL,
    -- Active Status of the Rule Set
    [IsActive] BIT NOT NULL CONSTRAINT DF_RuleSets_IsActive DEFAULT 1,
    -- Optional Description of the Rule Set
    [Description] NVARCHAR(MAX) NULL,
    -- Versioning and Audit Fields
    [RecordVersion] VARCHAR(50) NOT NULL
        CONSTRAINT DF_RuleSets_RecordVersion DEFAULT ([dbo].[fn_CalculateVersion](NULL)),
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME2(3) NOT NULL CONSTRAINT DF_RuleSets_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_RuleSets PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_RuleSets_PublicId UNIQUE ([PublicId] ASC),
    CONSTRAINT UQ_RuleSets_WorkflowName UNIQUE ([WorkflowName] ASC),
    CONSTRAINT CK_RuleSets_RuleContentJson
        CHECK (ISJSON([RuleContent]) = 1),
    CONSTRAINT CK_RuleSets_RecordVersionFormat
        CHECK ([RecordVersion] LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9]'),

    CONSTRAINT FK_RuleSets_RuleSetContextObjects FOREIGN KEY ([OutputDataTypeId])
        REFERENCES [dbo].[RuleSetContextObjects]([Id]),
    CONSTRAINT FK_RuleSets_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId])
);
GO

CREATE NONCLUSTERED INDEX IX_RuleSets_OutputDataTypeId
    ON [dbo].[RuleSets]([OutputDataTypeId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_RuleSets_IsActive
    ON [dbo].[RuleSets]([IsActive] ASC)
GO
