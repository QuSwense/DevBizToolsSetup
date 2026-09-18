/*
    This table is designed to store audit logs for direct execution of a group operations. 
    Each record captures the group execution details, status, and the user who performed the execution.

    Key Features:
    - Execution Tracking: Records the start and completion times of each execution.
    - Status and Details: Stores the execution status and detailed information in JSON or text format.
    - Auditing: Tracks the user who executed the operation and maintains timestamps for auditing purposes.
      There is no updation of existing records; each execution is logged as a new entry.

*/
CREATE TABLE [dbo].[DirectExecutionGroupAudits] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Public Identifier for UI/Secure Operations (GUID)
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_DirectExecutionGroupAudits_PublicId DEFAULT NEWID(),
    -- Name of the group operation being executed
    [Name] NVARCHAR(200) NOT NULL,
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

    CONSTRAINT PK_DirectExecutionGroupAudits PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_DirectExecutionGroupAudits_PublicId UNIQUE ([PublicId] ASC),
    CONSTRAINT UQ_DirectExecutionGroupAudits_Name UNIQUE ([Name] ASC),
    CONSTRAINT CK_DirectExecutionGroupAudits_ExecutionStatus CHECK ([ExecutionStatus] IN ('Pending', 'InProgress', 'Completed', 'Failed')),

    CONSTRAINT FK_DirectExecutionGroupAudits_Users_ExecutedBy
        FOREIGN KEY ([ExecutedBy]) REFERENCES [dbo].[Users]([UserId])
);
GO
