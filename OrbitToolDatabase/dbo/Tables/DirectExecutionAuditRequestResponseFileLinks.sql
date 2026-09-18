/*
    This table is designed to store links between direct execution audit group records and their associated request and response files.
    Each record captures the execution details, HTTP response information, and the user who performed the execution.

    Key Features:
    - Execution Tracking: Records the start and completion times of each execution.
    - HTTP Response Details: Stores HTTP status code, headers, content type, and content length.
    - Auditing: Tracks the user who executed the operation and maintains timestamps for auditing purposes. There is no updation of existing records; each execution is logged as a new entry.

*/
CREATE TABLE [dbo].[DirectExecutionAuditRequestResponseFileLinks] (
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    -- Public Identifier for UI/Secure Operations (GUID)
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_DirectExecutionAuditRequestResponseFileLinks_PublicId DEFAULT NEWID(),
    [DirectExecutionGroupAuditId] INT NOT NULL,
    [ServiceRequestFileId] INT NOT NULL,
    [ServiceResponseFileId] INT NOT NULL,
    [HttpExecutionDetailAuditId] INT NOT NULL,
    -- Execution order within the audit
    [ExecutionOrder] INT NOT NULL CONSTRAINT DF_DirectExecutionAuditRequestResponseFileLinks_ExecutionOrder DEFAULT 0,

    CONSTRAINT UQ_DirectExecutionAuditRequestResponseFileLinks_PublicId UNIQUE ([PublicId] ASC),
    CONSTRAINT UQ_DirectExecutionAuditRequestResponseFileLinks_Audit_Request_Response
        UNIQUE ([DirectExecutionGroupAuditId] ASC, [ServiceRequestFileId] ASC, [ServiceResponseFileId] ASC),
    CONSTRAINT PK_DirectExecutionAuditRequestResponseFileLinks PRIMARY KEY CLUSTERED ([Id] ASC),

    CONSTRAINT FK_DirectExecutionAuditRequestResponseFileLinks_DirectExecutionGroupAudit_DirectExecutionGroupAuditId
        FOREIGN KEY ([DirectExecutionGroupAuditId]) REFERENCES [dbo].[DirectExecutionGroupAudit]([Id]),
    CONSTRAINT FK_DirectExecutionAuditRequestResponseFileLinks_ServiceRequestFiles_ServiceRequestFileId
        FOREIGN KEY ([ServiceRequestFileId]) REFERENCES [dbo].[ServiceRequestFiles]([Id]),
    -- NO ACTION: ServiceRequestFiles is already reachable via ServiceResponseFiles (which cascades
    -- from ServiceRequestFiles), so CASCADE here would create a multiple-cascade-path error (Msg 1785).
    CONSTRAINT FK_DirectExecutionAuditRequestResponseFileLinks_ServiceResponseFiles_ServiceResponseFileId
        FOREIGN KEY ([ServiceResponseFileId]) REFERENCES [dbo].[ServiceResponseFiles]([Id]),
    CONSTRAINT FK_DirectExecutionAuditRequestResponseFileLinks_HttpExecutionDetailAudits_HttpExecutionDetailAuditId
        FOREIGN KEY ([HttpExecutionDetailAuditId]) REFERENCES [dbo].[HttpExecutionDetailAudits]([Id])
    
);
GO

-- Performance Indexes
CREATE NONCLUSTERED INDEX IX_DirectExecutionAuditRequestResponseFileLinks_ServiceRequestFileId
    ON [dbo].[DirectExecutionAuditRequestResponseFileLinks]([ServiceRequestFileId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_DirectExecutionAuditRequestResponseFileLinks_ServiceResponseFileId
    ON [dbo].[DirectExecutionAuditRequestResponseFileLinks]([ServiceResponseFileId] ASC)
GO
