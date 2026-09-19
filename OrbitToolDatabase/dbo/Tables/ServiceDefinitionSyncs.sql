/* 
    Table: ServiceDefinitionSyncs
    Description: Stores the synchronization details of service definitions (WSDL, Swagger, OpenAPI) for service applications.
    Logic:
    - In the UI there will be a Sync button to fetch the latest definition file from the service application.
*/
CREATE TABLE [dbo].[ServiceDefinitionSyncs] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] INT IDENTITY(1,1) NOT NULL,
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_ServiceDefinitionSyncs_PublicId DEFAULT NEWID(),
    -- Foreign Key to ServiceApplications table
    [ServiceApplicationId] INT NOT NULL,
    -- URL of the definition file (WSDL, Swagger, OpenAPI)
    [DefinitionUrl] NVARCHAR(1024) NULL,
    -- compressed content of the definition file (WSDL, Swagger, OpenAPI)
    [CompressedContent] VARBINARY(MAX) NOT NULL,
    -- uncompressed size of the definition file in bytes
    [UncompressedSizeBytes] BIGINT NULL,
    -- compression algorithm used for the definition file, e.g., 'Zstandard', 'Brotli', 'Gzip', 'none'
    [CompressionAlgorithmType] VARCHAR(50) NULL,
    -- Record version for optimistic concurrency control, formatted as 'YY.QQ.NN', e.g., '24.10.01'
    [RecordVersion] VARCHAR(50) NOT NULL
        CONSTRAINT DF_ServiceDefinitionSyncs_RecordVersion DEFAULT ([dbo].[fn_CalculateVersion](NULL)),
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME2(3) NOT NULL CONSTRAINT DF_ServiceDefinitionSyncs_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_ServiceDefinitionSyncs PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_ServiceDefinitionSyncs_PublicId_RecordVersion UNIQUE ([PublicId] ASC, [RecordVersion] ASC),
    CONSTRAINT UQ_ServiceDefinitionSyncs_ServiceApplicationId_RecordVersion
        UNIQUE NONCLUSTERED ([ServiceApplicationId] ASC, [RecordVersion] ASC),

    CONSTRAINT CK_ServiceDefinitionSyncs_DefinitionUrl
        CHECK ([DefinitionUrl] IS NULL
            OR LEFT([DefinitionUrl], 7) = 'http://'
            OR LEFT([DefinitionUrl], 8) = 'https://'),
    CONSTRAINT CK_ServiceDefinitionSyncs_CompressionAlgorithmType
        CHECK ([CompressionAlgorithmType] IS NULL OR [CompressionAlgorithmType] IN ('Zstandard', 'Brotli', 'Gzip', 'none')),
    CONSTRAINT CK_ServiceDefinitionSyncs_RecordVersionFormat
        CHECK ([RecordVersion] LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9]'),

    -- Foreign keys
    CONSTRAINT FK_ServiceDefinitionSyncs_ServiceApplications_ServiceApplicationId
        FOREIGN KEY ([ServiceApplicationId]) REFERENCES [dbo].[ServiceApplications]([Id]),
    CONSTRAINT FK_ServiceDefinitionSyncs_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId])
);
GO