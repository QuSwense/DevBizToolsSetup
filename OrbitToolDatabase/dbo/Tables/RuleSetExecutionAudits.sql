/*
    Table: RuleSetExecutionAudits
    Description: Logs the execution of rules, including input context, success status, results, and any error messages.
    Logic: Each log entry is associated with a specific rule set and captures the execution context, result, and metadata for auditing purposes.
*/
CREATE TABLE [dbo].[RuleSetExecutionAudits] (
    -- Primary Key and Identity
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    -- Public Identifier for UI/Secure Operations (GUID)
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_RuleSetExecutionAudits_PublicId DEFAULT NEWID(),
    -- Foreign Key Reference to RuleSets
    [RuleSetId] INT NOT NULL,
    [IsSuccess] BIT NOT NULL,
    [ExecutionDetails] NVARCHAR(MAX) NULL, -- Json
    [ExecutionTimeMs] INT NULL,
    [ExecutedAt] DATETIME2(3) NOT NULL CONSTRAINT DF_RuleSetExecutionAudits_ExecutedAt DEFAULT GETDATE(),
    [ExecutedBy] NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_RuleSetExecutionAudits PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_RuleSetExecutionAudits_PublicId UNIQUE ([PublicId] ASC),

    CONSTRAINT FK_RuleSetExecutionAudits_RuleSets FOREIGN KEY ([RuleSetId])
        REFERENCES [dbo].[RuleSets]([Id]),
    CONSTRAINT FK_RuleSetExecutionAudits_Users_ExecutedBy
        FOREIGN KEY ([ExecutedBy]) REFERENCES [dbo].[Users]([UserId])
);
GO

CREATE NONCLUSTERED INDEX IX_RuleSetExecutionAudits_RuleSetId
    ON [dbo].[RuleSetExecutionAudits]([RuleSetId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_RuleSetExecutionAudits_ExecutedAt
    ON [dbo].[RuleSetExecutionAudits]([ExecutedAt] ASC)
GO
