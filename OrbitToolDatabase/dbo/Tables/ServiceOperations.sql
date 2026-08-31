/*
    Table: ServiceOperations
    Description: Stores information about service operations (SOAP or REST) for each service application.
    Logic:
    - Each service application can have multiple operations, each with its own details such as operation name, endpoint/action, HTTP method, input/output root element names, and description.
    - The table should store various service operations with their respective details.
    - The ServiceApplicationId field is used to link the service operation to its parent service application. The RecordVersion field is used to track changes to the service operation record for optimistic concurrency control.
*/
CREATE TABLE [dbo].[ServiceOperations] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Foreign Key to ServiceApplications table
    [ServiceApplicationId] INT NOT NULL,
    -- Name of the service operation, e.g., 'GetUser', 'CreateOrder'
    [OperationName] NVARCHAR(200) NOT NULL,
    -- Endpoint Url for REST e.g., '/api/users' or action Name for soap e.g., 'GetUserDetails'
    [EndpointOrAction] NVARCHAR(500) NULL,
    -- HTTP method for REST operations, e.g., 'GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS'. For SOAP operations, this field can be POST only.
    [HttpMethod] VARCHAR(10) NULL,
    -- Optional description of the service operation, providing additional context or information about its purpose and functionality
    [Description] NVARCHAR(MAX) NULL,
    -- Indicates if the service operation record is currently active
    [IsActive] BIT NOT NULL CONSTRAINT DF_ServiceOperations_IsActive DEFAULT 1,
    -- Record version for optimistic concurrency control, formatted as 'YY.QQ.NN', e.g., '24.10.01'
    [RecordVersion] VARCHAR(50) NOT NULL
        CONSTRAINT DF_ServiceOperations_RecordVersion DEFAULT ([dbo].[fn_CalculateVersion](NULL)),
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceOperations_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT PK_ServiceOperations PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_ServiceOperations_ServiceApplicationId_OperationName_RecordVersion
        UNIQUE NONCLUSTERED ([ServiceApplicationId] ASC, [OperationName] ASC),

    CONSTRAINT CK_ServiceOperations_HttpMethod
        CHECK ([HttpMethod] IS NULL OR [HttpMethod] IN ('GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS')),
    CONSTRAINT CK_ServiceOperations_RecordVersionFormat
        CHECK ([RecordVersion] LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9]'),

    -- Foreign keys
    CONSTRAINT FK_ServiceOperations_ServiceApplications_ServiceApplicationId
        FOREIGN KEY ([ServiceApplicationId]) REFERENCES [dbo].[ServiceApplications]([Id]),
    CONSTRAINT FK_ServiceOperations_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_ServiceOperations_Users_LastUpdatedBy
        FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
)
GO

CREATE NONCLUSTERED INDEX IX_ServiceOperations_ServiceApplicationId
    ON [dbo].[ServiceOperations]([ServiceApplicationId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_ServiceOperations_IsActive
    ON [dbo].[ServiceOperations]([IsActive] ASC)
