/*
    This table is designed to store audit logs for direct execution of operations. Each record captures the execution details, status, and the user who performed the execution.

    Key Features:
    - Execution Tracking: Records the start and completion times of each execution.
    - Status and Details: Stores the execution status and detailed information in JSON or text format.
    - Auditing: Tracks the user who executed the operation and maintains timestamps for auditing purposes. There is no updation of existing records; each execution is logged as a new entry.

*/
CREATE TABLE [dbo].[DirectExecutionAudit] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Public Identifier for UI/Secure Operations (GUID)
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_DirectExecutionAudit_PublicId DEFAULT NEWID(),
    [Name] NVARCHAR(200) NOT NULL,
    [ExecutedAt] DATETIME NOT NULL CONSTRAINT DF_DirectExecutionAudit_ExecutedAt DEFAULT GETDATE(),
    [ExecutionCompletedAt] DATETIME NULL,
    [ExecutionStatus] NVARCHAR(50) NOT NULL,
    [ExecutionDetails] NVARCHAR(MAX) NULL, -- JSON or text details about the execution
    [ExecutedBy] NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_DirectExecutionAudit PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_DirectExecutionAudit_PublicId UNIQUE ([PublicId] ASC),
    CONSTRAINT CK_DirectExecutionAudit_ExecutionStatus CHECK ([ExecutionStatus] IN ('Pending', 'InProgress', 'Completed', 'Failed')),

    CONSTRAINT FK_DirectExecutionAudit_Users_ExecutedBy
        FOREIGN KEY ([ExecutedBy]) REFERENCES [dbo].[Users]([UserId])
);
GO
