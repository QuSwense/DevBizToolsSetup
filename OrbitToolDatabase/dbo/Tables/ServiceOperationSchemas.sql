/*
    Table: ServiceOperationSchemas
    Description: Stores the XML schema definitions for the input and output messages of service operations.
    Each record is associated with a specific service definition sync and optionally a specific service operation.
    The schema content is stored as XML in the SchemaContent column.
    Logic:
    - Mainly extracted automatically from the WSDL or OpenAPI definition files during the service definition sync process.
    - The InputRootElementName and OutputRootElementName fields are used to identify the root elements of the input and output messages for the service operation, respectively.
    - The TargetNamespace field is used to specify the XML namespace for the schema, which is important for XML validation and processing.
*/
CREATE TABLE [dbo].[ServiceOperationSchemas] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Foreign Key to ServiceDefinitionSyncs table
    [ServiceDefinitionSyncId] INT NOT NULL,
    -- Foreign Key to ServiceOperations table (optional)
    [ServiceOperationId] INT NULL,
    -- Root element name for the input message of the operation, e.g., 'GetUserRequest', 'CreateOrderRequest'
    [InputRootElementName] NVARCHAR(200) NULL,
    -- Root element name for the output message of the operation, e.g., 'GetUserResponse', 'CreateOrderResponse'
    [OutputRootElementName] NVARCHAR(200) NULL,
    -- Target namespace for the schema, e.g., 'http://example.com/soap/service', 'http://example.com/api/v1'
    [TargetNamespace] NVARCHAR(500) NULL,
    -- XML schema content for the operation's input and output messages
    [CompressedSchemaContent] NVARCHAR(MAX) NOT NULL,
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME NOT NULL
        CONSTRAINT [DF_ServiceOperationSchemas_CreatedAt] DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    -- Primary Key
    CONSTRAINT [PK_ServiceOperationSchemas] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT CK_ServiceOperationSchemas_TargetNamespace
        CHECK ([TargetNamespace] IS NULL OR LEFT([TargetNamespace], 7) = 'http://' OR LEFT([TargetNamespace], 8) = 'https://'),
    -- Check schema content is xml
    CONSTRAINT CK_ServiceOperationSchemas_SchemaContent
        CHECK (TRY_CAST([CompressedSchemaContent] AS XML) IS NOT NULL),

    -- Foreign Keys
    CONSTRAINT [FK_ServiceOperationSchemas_ServiceDefinitionSync_ServiceDefinitionSyncId]
        FOREIGN KEY ([ServiceDefinitionSyncId])
        REFERENCES [dbo].[ServiceDefinitionSyncs]([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_ServiceOperationSchemas_ServiceOperations_ServiceOperationId]
        FOREIGN KEY ([ServiceOperationId])
        REFERENCES [dbo].[ServiceOperations]([Id])
)
GO

CREATE NONCLUSTERED INDEX [IX_ServiceOperationSchemas_ServiceDefinitionSyncId]
    ON [dbo].[ServiceOperationSchemas]([ServiceDefinitionSyncId] ASC)
GO

CREATE NONCLUSTERED INDEX [IX_ServiceOperationSchemas_ServiceOperationId]
    ON [dbo].[ServiceOperationSchemas]([ServiceOperationId] ASC)
