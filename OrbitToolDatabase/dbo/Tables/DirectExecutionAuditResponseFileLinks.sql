CREATE TABLE [dbo].[DirectExecutionAuditResponseFileLinks] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [DirectExecutionAuditId] INT NOT NULL,
    [ServiceRequestFileId] INT NOT NULL,
    [ServiceResponseFileId] INT NOT NULL,
    [ExecutedAt] DATETIME NOT NULL CONSTRAINT DF_DirectExecutionAuditResponseFileLinks_ExecutedAt DEFAULT GETDATE(),
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

    CONSTRAINT PK_DirectExecutionAuditResponseFileLinks PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT FK_DirectExecutionAuditResponseFileLinks_DirectExecutionAudit_DirectExecutionAuditId
        FOREIGN KEY ([DirectExecutionAuditId]) REFERENCES [dbo].[DirectExecutionAudit]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_DirectExecutionAuditResponseFileLinks_ServiceRequestFiles_ServiceRequestFileId
        FOREIGN KEY ([ServiceRequestFileId]) REFERENCES [dbo].[ServiceRequestFiles]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_DirectExecutionAuditResponseFileLinks_ServiceResponseFiles_ServiceResponseFileId
        FOREIGN KEY ([ServiceResponseFileId]) REFERENCES [dbo].[ServiceResponseFiles]([Id]) ON DELETE CASCADE
)
