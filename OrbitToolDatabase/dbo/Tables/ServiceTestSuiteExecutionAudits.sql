/*
    Table: ServiceTestSuiteExecutionAudits
    Description: This table represents the execution audits for service test suites.
*/
CREATE TABLE [dbo].[ServiceTestSuiteExecutionAudits] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Foreign Key to ServiceTestSuites
    [ServiceTestSuiteId] INT NOT NULL,
    -- Execution started at
    [ExecutedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceTestSuiteExecutionAudits_ExecutedAt DEFAULT GETDATE(),
    -- Execution completed at
    [ExecutionCompletedAt] DATETIME NULL,
    -- Execution status (e.g., 'Pending', 'In Progress', 'Completed', 'Failed')
    [ExecutionStatus] NVARCHAR(50) NOT NULL,
    -- Execution details in JSON or text format, providing additional information about the execution process, such as logs, error messages, or any other relevant data.
    [ExecutionDetails] NVARCHAR(MAX) NULL, -- JSON or text details about the execution
    -- User who executed the test suite
    [ExecutedBy] NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_ServiceTestSuiteExecutionAudits PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT FK_ServiceTestSuiteExecutionAudits_ServiceTestSuites_ServiceTestSuiteId
        FOREIGN KEY ([ServiceTestSuiteId]) REFERENCES [dbo].[ServiceTestSuites]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceTestSuiteExecutionAudits_Users_ExecutedBy
        FOREIGN KEY ([ExecutedBy]) REFERENCES [dbo].[Users]([UserId])
)
