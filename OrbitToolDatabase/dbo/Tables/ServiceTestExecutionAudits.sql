CREATE TABLE [dbo].[ServiceTestExecutionAudits] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [ServiceTestSuiteId] INT NOT NULL,
    [ExecutedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceTestExecutionAudits_ExecutedAt DEFAULT GETDATE(),
    [ExecutionCompletedAt] DATETIME NULL,
    [ExecutionStatus] NVARCHAR(50) NOT NULL,
    [ExecutionDetails] NVARCHAR(MAX) NULL, -- JSON or text details about the execution
    [ExecutedBy] NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_ServiceTestExecutionAudits PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT FK_ServiceTestExecutionAudits_ServiceTestSuites_ServiceTestSuiteId
        FOREIGN KEY ([ServiceTestSuiteId]) REFERENCES [dbo].[ServiceTestSuites]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceTestExecutionAudits_Users_ExecutedBy
        FOREIGN KEY ([ExecutedBy]) REFERENCES [dbo].[Users]([UserId])
)
