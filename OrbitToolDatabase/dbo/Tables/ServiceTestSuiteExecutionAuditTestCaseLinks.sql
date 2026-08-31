/*
    Table: ServiceTestSuiteExecutionAuditTestCaseLinks
    Description: This table links service test suite execution audits to individual test cases, capturing detailed execution information for each test case within a suite. It includes HTTP response details, execution status, and timestamps for tracking the execution lifecycle.
*/
CREATE TABLE [dbo].[ServiceTestSuiteExecutionAuditTestCaseLinks] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [ServiceTestSuiteExecutionAuditId] INT NOT NULL,
    [ServiceTestCaseId] INT NOT NULL,
    [ServiceResponseFileId] INT NOT NULL,
    [ExecutedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceTestSuiteExecutionAuditTestCaseLinks_ExecutedAt DEFAULT GETDATE(),
    [ExecutionCompletedAt] DATETIME NULL,
    [HttpStatusCode] INT NULL, -- Response status code (200, 404, 500, etc.)
    [HttpVersion] NVARCHAR(10) NULL, -- HTTP/1.1, HTTP/2, HTTP/3
    [HttpRequestDurationMs] INT NULL, -- Total request duration in milliseconds
    [HttpRequestHeaders] NVARCHAR(MAX) NULL, -- JSON of request headers
    [HttpResponseHeaders] NVARCHAR(MAX) NULL, -- JSON of response headers
    [HttpContentType] NVARCHAR(255) NULL, -- Content-Type from response
    [HttpContentLength] BIGINT NULL, -- Response content length in bytes
    [ExecutionStatus] NVARCHAR(50) NOT NULL,
    [ExecutionDetails] NVARCHAR(MAX) NULL, -- JSON or text details about the execution like ErrorType, ErrorMessage, StackTrace, etc.
    [ExecutedBy] NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_ServiceTestSuiteExecutionAuditTestCaseLinks PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_ServiceTestSuiteExecutionAuditTestCaseLinks_ServiceTestSuiteExecutionAuditId_ServiceTestCaseId UNIQUE ([ServiceTestSuiteExecutionAuditId], [ServiceTestCaseId]),
    CONSTRAINT CK_ServiceTestSuiteExecutionAuditTestCaseLinks_HttpStatusCode CHECK ([HttpStatusCode] IS NULL OR ([HttpStatusCode] >= 100 AND [HttpStatusCode] <= 599)),
    CONSTRAINT CK_ServiceTestSuiteExecutionAuditTestCaseLinks_HttpVersion CHECK ([HttpVersion] IS NULL OR [HttpVersion] IN ('HTTP/1.0', 'HTTP/1.1', 'HTTP/2', 'HTTP/3')),
    CONSTRAINT CK_ServiceTestSuiteExecutionAuditTestCaseLinks_ExecutionStatus CHECK ([ExecutionStatus] IN ('Pending', 'InProgress', 'Completed', 'Failed')),
    CONSTRAINT FK_ServiceTestSuiteExecutionAuditTestCaseLinks_Users_ExecutedBy
        FOREIGN KEY ([ExecutedBy]) REFERENCES [dbo].[Users]([UserId]),

    CONSTRAINT FK_ServiceTestSuiteExecutionAuditTestCaseLinks_ServiceTestSuiteExecutionAudits_ServiceTestSuiteExecutionAuditId
        FOREIGN KEY ([ServiceTestSuiteExecutionAuditId]) REFERENCES [dbo].[ServiceTestSuiteExecutionAudits]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceTestSuiteExecutionAuditTestCaseLinks_ServiceTestCases_ServiceTestCaseId
        FOREIGN KEY ([ServiceTestCaseId]) REFERENCES [dbo].[ServiceTestCases]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceTestSuiteExecutionAuditTestCaseLinks_ServiceResponseFiles_ServiceResponseFileId
        FOREIGN KEY ([ServiceResponseFileId]) REFERENCES [dbo].[ServiceResponseFiles]([Id]) ON DELETE CASCADE
)
