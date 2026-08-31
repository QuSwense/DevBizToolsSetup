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
    [ServiceOperationId] INT NOT NULL,
    -- Root element name for the input message of the operation, e.g., 'GetUserRequest', 'CreateOrderRequest'
    [InputRootElementName] NVARCHAR(200) NULL,
    -- Root element name for the output message of the operation, e.g., 'GetUserResponse', 'CreateOrderResponse'
    [OutputRootElementName] NVARCHAR(200) NULL,
    -- Target namespace for the schema, e.g., 'http://example.com/soap/service', 'http://example.com/api/v1'
    [TargetNamespace] NVARCHAR(500) NULL,
    -- compressed content of the definition file (WSDL, Swagger, OpenAPI)
    [CompressedContent] VARBINARY(MAX) NOT NULL,
    -- uncompressed size of the definition file in bytes
    [UncompressedSizeBytes] INT NULL,
    -- compression algorithm used for the definition file, e.g., 'Zstandard', 'Brotli', 'Gzip', 'none'
    [CompressionAlgorithmType] VARCHAR(50) NULL,
    -- SHA256 hash of the definition file content for integrity verification
    [ContentHash] VARCHAR(64) NULL,
    -- Record version for optimistic concurrency control, formatted as 'YY.QQ.NN', e.g., '24.10.01'
    [RecordVersion] VARCHAR(50) NOT NULL
        CONSTRAINT DF_ServiceOperationSchemas_RecordVersion DEFAULT ([dbo].[fn_CalculateVersion](NULL)),
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME NOT NULL
        CONSTRAINT [DF_ServiceOperationSchemas_CreatedAt] DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    -- Primary Key
    CONSTRAINT [PK_ServiceOperationSchemas] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_ServiceOperationSchemas_ServiceDefinitionSyncId_ServiceOperationId_RecordVersion
        UNIQUE NONCLUSTERED ([ServiceDefinitionSyncId] ASC, [ServiceOperationId] ASC, [RecordVersion] ASC),

    CONSTRAINT CK_ServiceOperationSchemas_CompressionAlgorithmType
        CHECK ([CompressionAlgorithmType] IS NULL OR [CompressionAlgorithmType] IN ('Zstandard', 'Brotli', 'Gzip', 'none')),
    CONSTRAINT CK_ServiceOperationSchemas_ContentHash
        CHECK ([ContentHash] IS NULL OR LEN([ContentHash]) = 64 AND [ContentHash] NOT LIKE '%[^0-9a-fA-F]%'),
    CONSTRAINT CK_ServiceOperationSchemas_SchemaContent
        CHECK (TRY_CAST([CompressedContent] AS XML) IS NOT NULL),

    -- Foreign Keys
    CONSTRAINT [FK_ServiceOperationSchemas_ServiceDefinitionSyncs_ServiceDefinitionSyncId]
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
