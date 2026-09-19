/*
    This table is designed to store links between direct execution audit group records and their associated request and response files.
    Each record captures the execution details, HTTP response information, and the user who performed the execution.

    Key Features:
    - Execution Tracking: Records the start and completion times of each execution.
    - HTTP Response Details: Stores HTTP status code, headers, content type, and content length.
    - Auditing: Tracks the user who executed the operation and maintains timestamps for auditing purposes. There is no updation of existing records; each execution is logged as a new entry.

*/
CREATE TABLE [dbo].[DirectExecutionGroupServiceRequestFileLinkAudits] (
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    -- Public Identifier for UI/Secure Operations (GUID)
    [DirectExecutionGroupServiceRequestFileLinkId] INT NOT NULL,
    [ServiceResponseFileId] INT NOT NULL,
    -- Execution order within the audit
    [ExecutionOrder] INT NOT NULL CONSTRAINT DF_DirectExecutionGroupServiceRequestFileLinkAudits_ExecutionOrder DEFAULT 0,
    -- Timestamp when the execution started
    [ExecutedAt] DATETIME2(3) NOT NULL CONSTRAINT DF_DirectExecutionGroupAudits_ExecutedAt DEFAULT GETDATE(),
    -- Timestamp when the execution completed
    [ExecutionCompletedAt] DATETIME2(3) NULL,
    -- Status of the execution (Pending, InProgress, Completed, Failed)
    [ExecutionStatus] NVARCHAR(50) NOT NULL,
    -- Detailed information about the execution in JSON or text format
    [ExecutionDetails] NVARCHAR(MAX) NULL,
    -- User who executed the operation
    [ExecutedBy] NVARCHAR(20) NOT NULL,

    CONSTRAINT UQ_DirectExecutionGroupServiceRequestFileLinkAudits_Audit_Request_Response
        UNIQUE ([DirectExecutionGroupServiceRequestFileLinkId] ASC),
    CONSTRAINT PK_DirectExecutionGroupServiceRequestFileLinkAudits PRIMARY KEY CLUSTERED ([Id] ASC),

    CONSTRAINT FK_DirectExecutionGroupServiceRequestFileLinkAudits_DirectExecutionGroupServiceRequestFileLinks_DirectExecutionGroupServiceRequestFileLinkId
        FOREIGN KEY ([DirectExecutionGroupServiceRequestFileLinkId]) REFERENCES [dbo].[DirectExecutionGroupServiceRequestFileLinks]([Id]),
    CONSTRAINT FK_DirectExecutionGroupServiceRequestFileLinkAudits_ServiceResponseFiles_ServiceResponseFileId
        FOREIGN KEY ([ServiceResponseFileId]) REFERENCES [dbo].[ServiceResponseFiles]([Id]),
    CONSTRAINT FK_DirectExecutionGroupServiceRequestFileLinkAudits_Users_ExecutedBy
        FOREIGN KEY ([ExecutedBy]) REFERENCES [dbo].[Users]([UserId])
);
GO

-- Performance Indexes
CREATE NONCLUSTERED INDEX IX_DirectExecutionGroupServiceRequestFileLinkAudits_DirectExecutionGroupServiceRequestFileLinkId
    ON [dbo].[DirectExecutionGroupServiceRequestFileLinkAudits]([DirectExecutionGroupServiceRequestFileLinkId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_DirectExecutionGroupServiceRequestFileLinkAudits_ServiceResponseFileId
    ON [dbo].[DirectExecutionGroupServiceRequestFileLinkAudits]([ServiceResponseFileId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_DirectExecutionGroupServiceRequestFileLinkAudits_ExecutedBy
    ON [dbo].[DirectExecutionGroupServiceRequestFileLinkAudits]([ExecutedBy] ASC)
GO