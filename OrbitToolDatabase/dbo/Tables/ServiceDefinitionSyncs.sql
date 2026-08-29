CREATE TABLE [dbo].[ServiceDefinitionSyncs] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [ServiceApplicationId] INT NOT NULL,
    [DefinitionUrl] NVARCHAR(500) NULL, -- Built from BaseUrl + DefinitionRelativeUrl
    [DefinitionContent] VARBINARY(MAX) NOT NULL, -- compressed content of the definition file (WSDL, Swagger, OpenAPI)
    [UncompressedSizeBytes] INT NULL,
    [CompressionAlgorithmType] VARCHAR(50) NULL, -- e.g., 'Zstandard', 'deflate', 'none'
    [FileHash] VARCHAR(64) NULL,
    [RecordVersion] VARCHAR(50) NOT NULL
        CONSTRAINT DF_ServiceDefinitionSyncs_RecordVersion DEFAULT ([dbo].[fn_CalculateVersion](NULL)),
    [SyncedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceDefinitionSync_SyncedAt DEFAULT GETDATE(),
    [SyncedBy] NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_ServiceDefinitionSyncs PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT CK_ServiceDefinitionSyncs_DefinitionUrl
        CHECK (LEFT([DefinitionUrl], 7) = 'http://' OR LEFT([DefinitionUrl], 8) = 'https://'),
    CONSTRAINT CK_ServiceDefinitionSyncs_CompressionAlgorithmType
        CHECK ([CompressionAlgorithmType] IS NULL OR [CompressionAlgorithmType] IN ('Zstandard', 'Brotli', 'Gzip', 'none')),
    CONSTRAINT CK_ServiceDefinitionSyncs_FileHash
        CHECK ([FileHash] IS NULL OR LEN([FileHash]) = 64 AND [FileHash] NOT LIKE '%[^0-9a-fA-F]%'),
    CONSTRAINT CK_ServiceDefinitionSyncs_RecordVersionFormat
        CHECK ([RecordVersion] LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9]'),

    -- Foreign keys
    CONSTRAINT FK_ServiceDefinitionSyncs_ServiceApplications_ServiceApplicationId
        FOREIGN KEY ([ServiceApplicationId]) REFERENCES [dbo].[ServiceApplications]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceDefinitionSyncs_Users_SyncedBy
        FOREIGN KEY ([SyncedBy]) REFERENCES [dbo].[Users]([UserId]),

    -- Index constraint
    CONSTRAINT IX_ServiceDefinitionSyncs_ServiceApplicationId UNIQUE NONCLUSTERED ([ServiceApplicationId] ASC)
)
