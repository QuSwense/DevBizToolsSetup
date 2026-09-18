/*
    Table: ServiceAppHealthcheck
    Description: Stores information about service operations (SOAP or REST) for each service application.
    Logic:
    - Each service application can have multiple operations, each with its own details such as operation name, endpoint/action, HTTP method, input/output root element names, and description.
    - The table should store various service operations with their respective details.
    - The ServiceApplicationId field is used to link the service operation to its parent service application. The RecordVersion field is used to track changes to the service operation record for optimistic concurrency control.
*/
CREATE TABLE [dbo].[ServiceAppHealthchecks] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Foreign Key to ServiceApplications table, sometimes user may not have wsdl extracted from application
    [ServiceApplicationId] INT NOT NULL,
    -- The full URL for the healthcheck endpoint of the service application
    [HealthcheckUrl] NVARCHAR(1024) NULL,
    [ExecutedAt] DATETIME2(3) NOT NULL CONSTRAINT DF_ServiceAppHealthcheck_ExecutedAt DEFAULT GETDATE(),
    [ExecutionCompletedAt] DATETIME2(3) NULL,
    [HttpStatusCode] INT NULL, -- Response status code (200, 404, 500, etc.)
    [HttpVersion] NVARCHAR(10) NULL, -- HTTP/1.1, HTTP/2, HTTP/3
    [HttpRequestDurationMs] INT NULL, -- Total request duration in milliseconds
    [HttpRequestHeaders] NVARCHAR(MAX) NULL, -- JSON of request headers
    [HttpResponseHeaders] NVARCHAR(MAX) NULL, -- JSON of response headers
    [HttpContentType] NVARCHAR(255) NULL, -- Content-Type from response
    [HttpContentLength] BIGINT NULL, -- Response content length in bytes
    [ExecutionDetails] NVARCHAR(MAX) NULL, -- JSON or text details about the execution like ErrorType, ErrorMessage, StackTrace, etc.
    [ExecutedBy] NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_ServiceAppHealthchecks PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_ServiceAppHealthchecks_PublicId_RecordVersion UNIQUE ([PublicId] ASC, [RecordVersion] ASC),

    CONSTRAINT CK_ServiceAppHealthchecks_HttpMethod
        CHECK ([HttpMethod] IS NULL OR [HttpMethod] IN ('GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS')),
    CONSTRAINT CK_ServiceAppHealthchecks_ExecutionStatus CHECK ([ExecutionStatus] IN ('Pending', 'InProgress', 'Completed', 'Failed')),
    CONSTRAINT CK_ServiceAppHealthchecks_HttpStatusCode CHECK ([HttpStatusCode] IS NULL OR ([HttpStatusCode] >= 100 AND [HttpStatusCode] <= 599)),

    -- Foreign keys
    CONSTRAINT FK_ServiceAppHealthchecks_ServiceApplications_ServiceApplicationId
        FOREIGN KEY ([ServiceApplicationId]) REFERENCES [dbo].[ServiceApplications]([Id]),
    CONSTRAINT FK_ServiceAppHealthchecks_ServiceDefinitionSyncs_ServiceDefinitionSyncId
        FOREIGN KEY ([ServiceDefinitionSyncId]) REFERENCES [dbo].[ServiceDefinitionSyncs]([Id]),
    CONSTRAINT FK_ServiceAppHealthchecks_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_ServiceAppHealthchecks_Users_LastUpdatedBy
        FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
);
GO

-- Uniqueness: ServiceDefinitionSyncId is nullable, so a plain UNIQUE over it does not
-- enforce uniqueness (NULLs compare as distinct). Split into two filtered indexes.
CREATE UNIQUE NONCLUSTERED INDEX IX_ServiceAppHealthchecks_App_Op_Version_NoSync
    ON [dbo].[ServiceAppHealthchecks]([ServiceApplicationId] ASC, [OperationName] ASC, [RecordVersion] ASC)
    WHERE [ServiceDefinitionSyncId] IS NULL
GO

CREATE UNIQUE NONCLUSTERED INDEX IX_ServiceAppHealthchecks_App_Op_Sync_Version
    ON [dbo].[ServiceAppHealthchecks]([ServiceApplicationId] ASC, [OperationName] ASC, [ServiceDefinitionSyncId] ASC, [RecordVersion] ASC)
    WHERE [ServiceDefinitionSyncId] IS NOT NULL
GO

CREATE NONCLUSTERED INDEX IX_ServiceAppHealthchecks_ServiceApplicationId
    ON [dbo].[ServiceAppHealthchecks]([ServiceApplicationId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_ServiceAppHealthchecks_ServiceDefinitionSyncId
    ON [dbo].[ServiceAppHealthchecks]([ServiceDefinitionSyncId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_ServiceAppHealthchecks_IsActive
    ON [dbo].[ServiceAppHealthchecks]([IsActive] ASC)
GO
