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
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_ServiceOperationSchemas_PublicId DEFAULT NEWID(),
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
    [UncompressedSizeBytes] BIGINT NULL,
    -- compression algorithm used for the definition file, e.g., 'Zstandard', 'Brotli', 'Gzip', 'none'
    [CompressionAlgorithmType] VARCHAR(50) NULL,
    -- Record version for optimistic concurrency control, formatted as 'YY.QQ.NN', e.g., '24.10.01'
    [RecordVersion] VARCHAR(50) NOT NULL
        CONSTRAINT DF_ServiceOperationSchemas_RecordVersion DEFAULT ([dbo].[fn_CalculateVersion](NULL)),
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME2(3) NOT NULL
        CONSTRAINT [DF_ServiceOperationSchemas_CreatedAt] DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME2(3) NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    -- Primary Key
    CONSTRAINT [PK_ServiceOperationSchemas] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_ServiceOperationSchemas_PublicId_RecordVersion UNIQUE ([PublicId] ASC, [RecordVersion] ASC),
    CONSTRAINT UQ_ServiceOperationSchemas_ServiceOperationId_RecordVersion
        UNIQUE NONCLUSTERED ([ServiceOperationId] ASC, [RecordVersion] ASC),

    CONSTRAINT CK_ServiceOperationSchemas_CompressionAlgorithmType
        CHECK ([CompressionAlgorithmType] IS NULL OR [CompressionAlgorithmType] IN ('Zstandard', 'Brotli', 'Gzip', 'none')),
    CONSTRAINT CK_ServiceOperationSchemas_RecordVersionFormat
        CHECK ([RecordVersion] LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9]'),

    -- Foreign Keys
    CONSTRAINT [FK_ServiceOperationSchemas_ServiceOperations_ServiceOperationId]
        FOREIGN KEY ([ServiceOperationId])
        REFERENCES [dbo].[ServiceOperations]([Id])
);
GO

CREATE NONCLUSTERED INDEX [IX_ServiceOperationSchemas_ServiceOperationId]
    ON [dbo].[ServiceOperationSchemas]([ServiceOperationId] ASC)
GO
