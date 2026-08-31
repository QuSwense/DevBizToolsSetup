/* 
    Table: ServiceDefinitionSyncs
    Description: Stores the synchronization details of service definitions (WSDL, Swagger, OpenAPI) for service applications.
    Logic:
    - In the UI there will be a Sync button to fetch the latest definition file from the service application.
*/
CREATE TABLE [dbo].[ServiceDefinitionSyncs] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Foreign Key to ServiceApplications table
    [ServiceApplicationId] INT NOT NULL,
    -- Built from BaseUrl + DefinitionRelativeUrl
    [DefinitionUrl] NVARCHAR(500) NULL,
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
        CONSTRAINT DF_ServiceDefinitionSyncs_RecordVersion DEFAULT ([dbo].[fn_CalculateVersion](NULL)),
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceDefinitionSyncs_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT PK_ServiceDefinitionSyncs PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_ServiceDefinitionSyncs_ServiceApplicationId_RecordVersion
        UNIQUE NONCLUSTERED ([ServiceApplicationId] ASC, [RecordVersion] ASC),

    CONSTRAINT CK_ServiceDefinitionSyncs_DefinitionUrl
        CHECK (LEFT([DefinitionUrl], 7) = 'http://' OR LEFT([DefinitionUrl], 8) = 'https://'),
    CONSTRAINT CK_ServiceDefinitionSyncs_CompressionAlgorithmType
        CHECK ([CompressionAlgorithmType] IS NULL OR [CompressionAlgorithmType] IN ('Zstandard', 'Brotli', 'Gzip', 'none')),
    CONSTRAINT CK_ServiceDefinitionSyncs_ContentHash
        CHECK ([ContentHash] IS NULL OR LEN([ContentHash]) = 64 AND [ContentHash] NOT LIKE '%[^0-9a-fA-F]%'),
    CONSTRAINT CK_ServiceDefinitionSyncs_RecordVersionFormat
        CHECK ([RecordVersion] LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9]'),

    -- Foreign keys
    CONSTRAINT FK_ServiceDefinitionSyncs_ServiceApplications_ServiceApplicationId
        FOREIGN KEY ([ServiceApplicationId]) REFERENCES [dbo].[ServiceApplications]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceDefinitionSyncs_Users_SyncedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_ServiceDefinitionSyncs_Users_LastUpdatedBy
        FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId]),

    -- Index constraint
    CONSTRAINT IX_ServiceDefinitionSyncs_ServiceApplicationId UNIQUE NONCLUSTERED ([ServiceApplicationId] ASC)
)
