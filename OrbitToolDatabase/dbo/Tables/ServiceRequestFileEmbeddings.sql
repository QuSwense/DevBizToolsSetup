CREATE TABLE [dbo].[ServiceRequestFileEmbeddings] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [ServiceRequestFileId] INT NULL,
    [ServiceRequestFileHistoryId] INT NULL,
    [FileFormat] VARCHAR(10) NULL,
    [FileName] NVARCHAR(250) NOT NULL,
    [FileData] VARBINARY(MAX) NOT NULL,
    [UncompressedSizeBytes] INT NULL,
    [CompressionAlgorithmType] VARCHAR(50) NULL,
    [FileHash] VARCHAR(64) NULL,
    [CreatedAt] DATETIME NOT NULL
        CONSTRAINT DF_ServiceRequestFileEmbeddings_CreatedAt DEFAULT GETDATE(),

    CONSTRAINT PK_ServiceRequestFileEmbeddings PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT CK_ServiceRequestFileEmbeddings_OneParent
        CHECK (
            ([ServiceRequestFileId] IS NOT NULL AND [ServiceRequestFileHistoryId] IS NULL)
            OR ([ServiceRequestFileId] IS NULL AND [ServiceRequestFileHistoryId] IS NOT NULL)
        ),
    CONSTRAINT CK_ServiceRequestFileEmbeddings_Format
        CHECK ([FileFormat] IS NULL OR [FileFormat] IN ('XML','JSON','PDF','BINARY')),
    CONSTRAINT CK_ServiceRequestFileEmbeddings_CompressionAlgorithmType
        CHECK ([CompressionAlgorithmType] IS NULL OR [CompressionAlgorithmType] IN ('Zstandard', 'Brotli', 'Gzip', 'none')),
    CONSTRAINT CK_ServiceRequestFileEmbeddings_FileHash
        CHECK ([FileHash] IS NULL OR LEN([FileHash]) = 64 AND [FileHash] NOT LIKE '%[^0-9a-fA-F]%'),

    CONSTRAINT FK_ServiceRequestFileEmbeddings_ServiceRequestFiles
        FOREIGN KEY ([ServiceRequestFileId]) REFERENCES [dbo].[ServiceRequestFiles]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceRequestFileEmbeddings_ServiceRequestFileHistorys
        FOREIGN KEY ([ServiceRequestFileHistoryId]) REFERENCES [dbo].[ServiceRequestFileHistorys]([Id])
)
