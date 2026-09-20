/*
    Table: ServiceTestSuiteTestCaseLinkAudits
    Description: This table links service test suite execution audits to individual test cases, capturing detailed execution information for each test case within a suite. It includes HTTP response details, execution status, and timestamps for tracking the execution lifecycle.
*/
CREATE TABLE [dbo].[ServiceTestSuiteTestCaseLinkAudits] (
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    [ServiceTestSuiteTestCaseLinkId] INT NOT NULL,
    [ServiceResponseFileId] BIGINT NOT NULL,
    -- Execution order within the audit
    [ExecutionOrder] INT NOT NULL CONSTRAINT DF_ServiceTestSuiteTestCaseLinkAudits_ExecutionOrder DEFAULT 0,
    -- Timestamp when the execution started
    [ExecutedAt] DATETIME2(3) NOT NULL CONSTRAINT DF_ServiceTestSuiteTestCaseLinkAudits_ExecutedAt DEFAULT GETDATE(),
    -- Timestamp when the execution completed
    [ExecutionCompletedAt] DATETIME2(3) NULL,
    -- Status of the execution (Pending, InProgress, Completed, Failed)
    [ExecutionStatus] NVARCHAR(50) NOT NULL,
    -- Detailed information about the execution in JSON or text format
    [ExecutionDetails] NVARCHAR(MAX) NULL,
    -- User who executed the operation
    [ExecutedBy] NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_ServiceTestSuiteTestCaseLinkAudits PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_ServiceTestSuiteTestCaseLinkAudits_ServiceTestSuiteTestCaseLinkId_ServiceResponseFileId UNIQUE ([ServiceTestSuiteTestCaseLinkId], [ServiceResponseFileId]),
    CONSTRAINT CK_ServiceTestSuiteTestCaseLinkAudits_ExecutionStatus CHECK ([ExecutionStatus] IN ('Pending', 'InProgress', 'Completed', 'Failed')),
    CONSTRAINT FK_ServiceTestSuiteTestCaseLinkAudits_Users_ExecutedBy
        FOREIGN KEY ([ExecutedBy]) REFERENCES [dbo].[Users]([UserId]),

    CONSTRAINT FK_ServiceTestSuiteTestCaseLinkAudits_ServiceTestSuiteTestCaseLinks_ServiceTestSuiteTestCaseLinkId
        FOREIGN KEY ([ServiceTestSuiteTestCaseLinkId]) REFERENCES [dbo].[ServiceTestSuiteTestCaseLinks]([Id]),
    CONSTRAINT FK_ServiceTestSuiteTestCaseLinkAudits_ServiceResponseFiles_ServiceResponseFileId
        FOREIGN KEY ([ServiceResponseFileId]) REFERENCES [dbo].[ServiceResponseFiles]([Id])
);
GO

CREATE NONCLUSTERED INDEX IX_ServiceTestSuiteTestCaseLinkAudits_ServiceResponseFileId
    ON [dbo].[ServiceTestSuiteTestCaseLinkAudits]([ServiceResponseFileId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_ServiceTestSuiteTestCaseLinkAudits_ServiceTestSuiteTestCaseLinkId
    ON [dbo].[ServiceTestSuiteTestCaseLinkAudits]([ServiceTestSuiteTestCaseLinkId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_ServiceTestSuiteTestCaseLinkAudits_ExecutedBy
    ON [dbo].[ServiceTestSuiteTestCaseLinkAudits]([ExecutedBy] ASC)
GO
