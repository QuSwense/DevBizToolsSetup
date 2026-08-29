CREATE TABLE [dbo].[RuleExecutionLogs] (
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
        REFERENCES [dbo].[RuleSets]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_RuleExecutionLogs_Users_ExecutedBy
        FOREIGN KEY ([ExecutedBy]) REFERENCES [dbo].[Users]([UserId])
)
