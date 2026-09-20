/*
    This table is designed to store links between direct execution audit group records and their associated request and response files.
    Each record captures the execution details, HTTP response information, and the user who performed the execution.

    Key Features:
    - Execution Tracking: Records the start and completion times of each execution.
    - HTTP Response Details: Stores HTTP status code, headers, content type, and content length.
    - Auditing: Tracks the user who executed the operation and maintains timestamps for auditing purposes. There is no updation of existing records; each execution is logged as a new entry.

*/
CREATE TABLE [dbo].[HttpExecutionDetailAuditsServiceResponseFilesLinks]
(
    -- Suppose to store large identifiers for service response files and HTTP execution detail audits
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    [ServiceResponseFileId] BIGINT NOT NULL,
    [HttpExecutionDetailAuditId] BIGINT NOT NULL,
    -- Timestamp when the execution started
    [ExecutedAt] DATETIME2(3) NOT NULL CONSTRAINT DF_HttpExecutionDetailAuditsServiceResponseFilesLinks_ExecutedAt DEFAULT GETDATE(),
    -- Timestamp when the execution completed
    [ExecutionCompletedAt] DATETIME2(3) NULL,
    -- Status of the execution (Pending, InProgress, Completed, Failed)
    [ExecutionStatus] NVARCHAR(50) NOT NULL,
    -- Detailed information about the execution in JSON or text format
    [ExecutionDetails] NVARCHAR(MAX) NULL,
    -- User who executed the operation
    [ExecutedBy] NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_HttpExecutionDetailAuditsServiceResponseFilesLinks PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT CK_HttpExecutionDetailAuditsServiceResponseFilesLinks_ExecutionStatus CHECK ([ExecutionStatus] IN ('Pending', 'InProgress', 'Completed', 'Failed')),
    CONSTRAINT UQ_HttpExecutionDetailAuditsServiceResponseFilesLinks_HttpExecutionDetailAuditId UNIQUE ([HttpExecutionDetailAuditId] ASC),

    -- Foreign keys
    CONSTRAINT FK_HttpExecutionDetailAuditsServiceResponseFilesLinks_ServiceResponseFiles_ServiceResponseFileId
        FOREIGN KEY ([ServiceResponseFileId]) REFERENCES [dbo].[ServiceResponseFiles]([Id]),
    CONSTRAINT FK_HttpExecutionDetailAuditsServiceResponseFilesLinks_HttpExecutionDetailAuditId
        FOREIGN KEY ([HttpExecutionDetailAuditId]) REFERENCES [dbo].[HttpExecutionDetailAudits]([Id]),
    CONSTRAINT FK_HttpExecutionDetailAuditsServiceResponseFilesLinks_Users_ExecutedBy
        FOREIGN KEY ([ExecutedBy]) REFERENCES [dbo].[Users]([UserId])
);
GO

CREATE NONCLUSTERED INDEX IX_HttpExecutionDetailAuditsServiceResponseFilesLinks_ServiceResponseFileId
    ON [dbo].[HttpExecutionDetailAuditsServiceResponseFilesLinks]([ServiceResponseFileId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_HttpExecutionDetailAuditsServiceResponseFilesLinks_HttpExecutionDetailAuditId
    ON [dbo].[HttpExecutionDetailAuditsServiceResponseFilesLinks]([HttpExecutionDetailAuditId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_HttpExecutionDetailAuditsServiceResponseFilesLinks_ExecutedBy
    ON [dbo].[HttpExecutionDetailAuditsServiceResponseFilesLinks]([ExecutedBy] ASC)
GO
