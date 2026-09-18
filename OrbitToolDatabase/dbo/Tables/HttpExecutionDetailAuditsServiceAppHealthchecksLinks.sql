/*
    This table is designed to store links between direct execution audit group records and their associated request and response files.
    Each record captures the execution details, HTTP response information, and the user who performed the execution.

    Key Features:
    - Execution Tracking: Records the start and completion times of each execution.
    - HTTP Response Details: Stores HTTP status code, headers, content type, and content length.
    - Auditing: Tracks the user who executed the operation and maintains timestamps for auditing purposes. There is no updation of existing records; each execution is logged as a new entry.

*/
CREATE TABLE [dbo].[HttpExecutionDetailAuditsServiceAppHealthchecksLinks]
(
    -- Suppose to store large identifiers for service response files and HTTP execution detail audits
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    [ServiceResponseFileId] BIGINT NOT NULL,
    [HttpExecutionDetailAuditId] BIGINT NOT NULL,

    CONSTRAINT UQ_HttpExecutionDetailAuditsServiceAppHealthchecksLinks_ServiceResponseFileId
        UNIQUE ([ServiceResponseFileId] ASC),
    CONSTRAINT PK_HttpExecutionDetailAuditsServiceAppHealthchecksLinks PRIMARY KEY CLUSTERED ([Id] ASC),

    CONSTRAINT FK_HttpExecutionDetailAuditsServiceAppHealthchecksLinks_ServiceResponseFiles_ServiceResponseFileId
        FOREIGN KEY ([ServiceResponseFileId]) REFERENCES [dbo].[ServiceResponseFiles]([Id]),
    CONSTRAINT FK_HttpExecutionDetailAuditsServiceAppHealthchecksLinks_HttpExecutionDetailAudits_HttpExecutionDetailAuditId
        FOREIGN KEY ([HttpExecutionDetailAuditId]) REFERENCES [dbo].[HttpExecutionDetailAudits]([Id])
    
);
GO

CREATE NONCLUSTERED INDEX IX_HttpExecutionDetailAuditsServiceAppHealthchecksLinks_ServiceResponseFileId
    ON [dbo].[HttpExecutionDetailAuditsServiceAppHealthchecksLinks]([ServiceResponseFileId] ASC)
GO
