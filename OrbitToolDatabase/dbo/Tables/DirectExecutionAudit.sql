CREATE TABLE [dbo].[DirectExecutionAudit] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Name] NVARCHAR(200) NOT NULL,
    [ExecutedAt] DATETIME NOT NULL CONSTRAINT DF_DirectExecutionAudit_ExecutedAt DEFAULT GETDATE(),
    [ExecutionCompletedAt] DATETIME NULL,
    [ExecutionStatus] NVARCHAR(50) NOT NULL,
    [ExecutionDetails] NVARCHAR(MAX) NULL, -- JSON or text details about the execution
    [ExecutedBy] NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_DirectExecutionAudit PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT FK_DirectExecutionAudit_Users_ExecutedBy
        FOREIGN KEY ([ExecutedBy]) REFERENCES [dbo].[Users]([UserId])
)
