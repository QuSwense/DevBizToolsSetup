/*
    Table: SoapNamespaces
    Description: Stores SOAP namespace definitions associated with service operation schemas.
*/
CREATE TABLE [dbo].[SoapNamespaces] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Foreign Key to ServiceOperationSchemas table
    [ServiceOperationSchemaId] INT NOT NULL,
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
        CONSTRAINT DF_SoapNamespaces_RecordVersion DEFAULT ([dbo].[fn_CalculateVersion](NULL)),
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME NOT NULL CONSTRAINT [DF_SoapNamespaces_CreatedAt] DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    -- Primary Key
    CONSTRAINT [PK_SoapNamespaces] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT CK_SoapNamespaces_CompressionAlgorithmType
        CHECK ([CompressionAlgorithmType] IS NULL OR [CompressionAlgorithmType] IN ('Zstandard', 'Brotli', 'Gzip', 'none')),
    CONSTRAINT CK_SoapNamespaces_ContentHash
        CHECK ([ContentHash] IS NULL OR LEN([ContentHash]) = 64 AND [ContentHash] NOT LIKE '%[^0-9a-fA-F]%'),
    CONSTRAINT CK_SoapNamespaces_RecordVersionFormat
        CHECK ([RecordVersion] LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9]'),

    -- Foreign Keys
    CONSTRAINT [FK_SoapNamespaces_ServiceOperationSchemas_ServiceOperationSchemaId]
        FOREIGN KEY ([ServiceOperationSchemaId]) REFERENCES [dbo].[ServiceOperationSchemas]([Id]) ON DELETE CASCADE
)
GO

CREATE NONCLUSTERED INDEX [IX_SoapNamespaces_ServiceOperationSchemaId]
    ON [dbo].[SoapNamespaces]([ServiceOperationSchemaId] ASC)
GO
