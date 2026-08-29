CREATE TABLE [dbo].[ServiceTestExecutionAuditTestSuitLinks] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [ServiceTestExecutionAuditId] INT NOT NULL,
    [ServiceTestCaseId] INT NOT NULL,
    [ServiceResponseFileId] INT NOT NULL,
    [ExecutedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceTestExecutionAuditTestSuitLinks_ExecutedAt DEFAULT GETDATE(),
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

    CONSTRAINT PK_ServiceTestExecutionAuditTestSuitLinks PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT FK_ServiceTestExecutionAuditTestSuitLinks_ServiceTestExecutionAudits_ServiceTestExecutionAuditId
        FOREIGN KEY ([ServiceTestExecutionAuditId]) REFERENCES [dbo].[ServiceTestExecutionAudits]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceTestExecutionAuditTestSuitLinks_ServiceTestCases_ServiceTestCaseId
        FOREIGN KEY ([ServiceTestCaseId]) REFERENCES [dbo].[ServiceTestCases]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceTestExecutionAuditTestSuitLinks_ServiceResponseFiles_ServiceResponseFileId
        FOREIGN KEY ([ServiceResponseFileId]) REFERENCES [dbo].[ServiceResponseFiles]([Id]) ON DELETE CASCADE
)
