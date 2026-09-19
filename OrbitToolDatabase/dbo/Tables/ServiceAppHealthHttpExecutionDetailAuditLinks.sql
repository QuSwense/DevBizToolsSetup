/*
    Table: ServiceAppHealthcheck
    Description: Stores information about service operations (SOAP or REST) for each service application.
    Logic:
    - Each service application can have multiple operations, each with its own details such as operation name, endpoint/action, HTTP method, input/output root element names, and description.
    - The table should store various service operations with their respective details.
    - The ServiceApplicationId field is used to link the service operation to its parent service application. The RecordVersion field is used to track changes to the service operation record for optimistic concurrency control.
*/
CREATE TABLE [dbo].[ServiceAppHealthHttpExecutionDetailAuditLinks] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Foreign Key to ServiceApplications table, sometimes user may not have wsdl extracted from application
    [ServiceApplicationId] INT NOT NULL,
    -- The full URL for the healthcheck endpoint of the service application
    [HttpExecutionDetailAuditId] BIGINT NOT NULL,
    -- Timestamp when the execution started
    [ExecutedAt] DATETIME2(3) NOT NULL CONSTRAINT DF_ServiceAppHealthHttpExecutionDetailAuditLinks_ExecutedAt DEFAULT GETDATE(),
    -- Timestamp when the execution completed
    [ExecutionCompletedAt] DATETIME2(3) NULL,
    -- Status of the execution (Pending, InProgress, Completed, Failed)
    [ExecutionStatus] NVARCHAR(50) NOT NULL,
    -- Detailed information about the execution in JSON or text format
    [ExecutionDetails] NVARCHAR(MAX) NULL,
    -- User who executed the operation
    [ExecutedBy] NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_ServiceAppHealthHttpExecutionDetailAuditLinks PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT CK_ServiceAppHealthHttpExecutionDetailAuditLinks_ExecutionStatus CHECK ([ExecutionStatus] IN ('Pending', 'InProgress', 'Completed', 'Failed')),
    CONSTRAINT UQ_ServiceAppHealthHttpExecutionDetailAuditLinks_HttpExecutionDetailAuditId UNIQUE ([HttpExecutionDetailAuditId] ASC),

    -- Foreign keys
    CONSTRAINT FK_ServiceAppHealthHttpExecutionDetailAuditLinks_ServiceApplications_ServiceApplicationId
        FOREIGN KEY ([ServiceApplicationId]) REFERENCES [dbo].[ServiceApplications]([Id]),
    CONSTRAINT FK_ServiceAppHealthHttpExecutionDetailAuditLinks_HttpExecutionDetailAuditId
        FOREIGN KEY ([HttpExecutionDetailAuditId]) REFERENCES [dbo].[HttpExecutionDetailAudits]([Id]),
    CONSTRAINT FK_ServiceAppHealthHttpExecutionDetailAuditLinks_Users_ExecutedBy
        FOREIGN KEY ([ExecutedBy]) REFERENCES [dbo].[Users]([UserId])
);
GO

CREATE NONCLUSTERED INDEX IX_ServiceAppHealthHttpExecutionDetailAuditLinks_ServiceApplicationId
    ON [dbo].[ServiceAppHealthHttpExecutionDetailAuditLinks]([ServiceApplicationId] ASC)
GO
