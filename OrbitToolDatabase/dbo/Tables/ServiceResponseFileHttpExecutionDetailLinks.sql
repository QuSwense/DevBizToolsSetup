/*
    This table is designed to store links between service response files and their associated HTTP execution detail audits.
    Each record captures the execution details and the user who performed the execution.

    Key Features:
    - Execution Tracking: Links service response files to their corresponding HTTP execution detail audits.
    - Auditing: Tracks the user who created the link and maintains timestamps for auditing purposes. There is no updation of existing records; each link is logged as a new entry.
*/
CREATE TABLE [dbo].[ServiceResponseFileHttpExecutionDetailLinks] (
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    [ServiceResponseFileId] INT NOT NULL,
    [HttpExecutionDetailAuditId] INT NOT NULL,
    [CreatedAt] DATETIME2(3) NOT NULL CONSTRAINT DF_ServiceResponseFileHttpExecutionDetailLinks_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,

    CONSTRAINT UQ_ServiceResponseFileHttpExecutionDetailLinks_Audit_Request_Response
        UNIQUE ([ServiceResponseFileId] ASC, [HttpExecutionDetailAuditId] ASC),
    CONSTRAINT PK_ServiceResponseFileHttpExecutionDetailLinks PRIMARY KEY CLUSTERED ([Id] ASC),

    CONSTRAINT FK_ServiceResponseFileHttpExecutionDetailLinks_ServiceResponseFiles_ServiceResponseFileId
        FOREIGN KEY ([ServiceResponseFileId]) REFERENCES [dbo].[ServiceResponseFiles]([Id]),
    CONSTRAINT FK_ServiceResponseFileHttpExecutionDetailLinks_HttpExecutionDetailAudits_HttpExecutionDetailAuditId
        FOREIGN KEY ([HttpExecutionDetailAuditId]) REFERENCES [dbo].[HttpExecutionDetailAudits]([Id]),
    CONSTRAINT FK_ServiceResponseFileHttpExecutionDetailLinks_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId])
);
GO

-- Performance Indexes
CREATE NONCLUSTERED INDEX IX_ServiceResponseFileHttpExecutionDetailLinks_ServiceResponseFileId
    ON [dbo].[ServiceResponseFileHttpExecutionDetailLinks]([ServiceResponseFileId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_ServiceResponseFileHttpExecutionDetailLinks_HttpExecutionDetailAuditId
    ON [dbo].[ServiceResponseFileHttpExecutionDetailLinks]([HttpExecutionDetailAuditId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_ServiceResponseFileHttpExecutionDetailLinks_CreatedBy
    ON [dbo].[ServiceResponseFileHttpExecutionDetailLinks]([CreatedBy] ASC)
GO