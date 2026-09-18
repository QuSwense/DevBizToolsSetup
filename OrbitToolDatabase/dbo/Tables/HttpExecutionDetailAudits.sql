/*
    This table is designed to store detailed HTTP execution audit records.
    Each record captures the execution details, HTTP response information, and the user who performed the execution.

    Key Features:
    - Execution Tracking: Records the start and completion times of each execution.
    - HTTP Response Details: Stores HTTP status code, headers, content type, and content length.
    - Compression Details: Stores compressed response content along with the original uncompressed size and compression algorithm used.
    - Auditing: Tracks the user who executed the operation and maintains timestamps for auditing purposes. There is no updation of existing records; each execution is logged as a new entry.
*/
CREATE TABLE [dbo].[HttpExecutionDetailAudits] (
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_HttpExecutionDetailAudits_PublicId DEFAULT NEWID(),
    [ExecutedAt] DATETIME2(3) NOT NULL CONSTRAINT DF_HttpExecutionDetailAudits_ExecutedAt DEFAULT GETDATE(),
    [ExecutionCompletedAt] DATETIME2(3) NULL,
    -- For GET it will contain query parameters appended to the URL.
    [HttpRequestUrl] NVARCHAR(MAX) NOT NULL,
    -- HTTP request method (e.g., 'GET', 'POST', 'PUT', 'DELETE').
    [HttpRequestMethod] NVARCHAR(10) NOT NULL,
    [HttpRequestHeaders] NVARCHAR(MAX) NULL,
    [HttpVersion] NVARCHAR(10) NULL,
    [HttpStatusCode] INT NULL,
    -- Duration of the HTTP request in milliseconds.
    [HttpRequestDurationMs] INT NULL,
    -- HTTP response headers
    [HttpResponseHeaders] NVARCHAR(MAX) NULL,
    [HttpContentType] NVARCHAR(255) NULL,
    [HttpContentLength] BIGINT NULL,
    [ExecutionStatus] NVARCHAR(50) NOT NULL,
    -- JSON containing additional execution details
    [ExecutionDetails] NVARCHAR(MAX) NULL,
    [ExecutedBy] NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_HttpExecutionDetailAudits PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_HttpExecutionDetailAudits_PublicId UNIQUE ([PublicId] ASC),
    CONSTRAINT CK_HttpExecutionDetailAudits_HttpStatusCode CHECK ([HttpStatusCode] IS NULL OR ([HttpStatusCode] >= 100 AND [HttpStatusCode] <= 599)),
    CONSTRAINT CK_HttpExecutionDetailAudits_HttpVersion CHECK ([HttpVersion] IS NULL OR [HttpVersion] IN ('HTTP/1.1', 'HTTP/2', 'HTTP/3')),
    CONSTRAINT CK_HttpExecutionDetailAudits_ExecutionStatus CHECK ([ExecutionStatus] IN ('Pending', 'InProgress', 'Completed', 'Failed')),

    CONSTRAINT FK_HttpExecutionDetailAudits_ExecutedBy_Users_ExecutedBy
        FOREIGN KEY ([ExecutedBy]) REFERENCES [dbo].[Users]([UserId])
);
GO