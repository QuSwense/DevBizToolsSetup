-- Populated only via trg_ServiceDefinitionSyncs_AutoUpdate
CREATE TABLE [dbo].[ServiceDefinitionSyncHistorys] (
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    [ServiceDefinitionSyncId] INT NOT NULL,
    [ServiceApplicationId] INT NOT NULL,
    [DefinitionUrl] NVARCHAR(500) NULL,
    [DefinitionContent] VARBINARY(MAX) NOT NULL,
    [UncompressedSizeBytes] INT NULL,
    [CompressionAlgorithmType] VARCHAR(50) NULL,
    [FileHash] VARCHAR(64) NULL,
    [RecordVersion] VARCHAR(50) NOT NULL,
    [SyncedAt] DATETIME NOT NULL,
    [SyncedBy] NVARCHAR(20) NOT NULL,
    [ChangedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceDefinitionSyncHistorys_ChangedAt DEFAULT GETDATE(),
    [ChangedBy] NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_ServiceDefinitionSyncHistorys PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT CK_ServiceDefinitionSyncHistorys_DefinitionUrl
        CHECK (LEFT([DefinitionUrl], 7) = 'http://' OR LEFT([DefinitionUrl], 8) = 'https://'),
    CONSTRAINT CK_ServiceDefinitionSyncHistorys_CompressionAlgorithmType
        CHECK ([CompressionAlgorithmType] IS NULL OR [CompressionAlgorithmType] IN ('Zstandard', 'Brotli', 'Gzip', 'none')),
    CONSTRAINT CK_ServiceDefinitionSyncHistorys_FileHash
        CHECK ([FileHash] IS NULL OR LEN([FileHash]) = 64 AND [FileHash] NOT LIKE '%[^0-9a-fA-F]%'),
    CONSTRAINT CK_ServiceDefinitionSyncHistorys_RecordVersionFormat
        CHECK ([RecordVersion] LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9]'),

    -- Foreign keys
    CONSTRAINT FK_ServiceDefinitionSyncHistorys_ServiceApplications_ServiceApplicationId
        FOREIGN KEY ([ServiceApplicationId]) REFERENCES [dbo].[ServiceApplications]([Id]),
    CONSTRAINT FK_ServiceDefinitionSyncHistorys_ServiceDefinitionSyncs_ServiceDefinitionSyncId
        FOREIGN KEY ([ServiceDefinitionSyncId]) REFERENCES [dbo].[ServiceDefinitionSyncs]([Id]),
    CONSTRAINT FK_ServiceDefinitionSyncHistorys_Users_SyncedBy
        FOREIGN KEY ([SyncedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_ServiceDefinitionSyncHistorys_Users_ChangedBy
        FOREIGN KEY ([ChangedBy]) REFERENCES [dbo].[Users]([UserId])
)
