CREATE TABLE [dbo].[ServiceResponseFileEmbeddings] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [ServiceResponseFileId] INT NOT NULL,
    [FileFormat] VARCHAR(10) NULL,
    [FileName] NVARCHAR(250) NOT NULL,
    [FileData] VARBINARY(MAX) NOT NULL,
    [UncompressedSizeBytes] INT NULL,
    [CompressionAlgorithmType] VARCHAR(50) NULL,
    [FileHash] VARCHAR(64) NULL,
    [CreatedAt] DATETIME NOT NULL
        CONSTRAINT [DF_ServiceResponseFileEmbeddings_CreatedAt] DEFAULT GETDATE(),

    CONSTRAINT [PK_ServiceResponseFileEmbeddings] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT CK_ServiceResponseFileEmbeddings_FileFormat
        CHECK ([FileFormat] IS NULL OR [FileFormat] IN ('XML','JSON','PDF','BINARY')),
    CONSTRAINT CK_ServiceResponseFileEmbeddings_CompressionAlgorithmType
        CHECK ([CompressionAlgorithmType] IS NULL OR [CompressionAlgorithmType] IN ('Zstandard', 'Brotli', 'Gzip', 'none')),
    CONSTRAINT CK_ServiceResponseFileEmbeddings_FileHash
        CHECK ([FileHash] IS NULL OR LEN([FileHash]) = 64 AND [FileHash] NOT LIKE '%[^0-9a-fA-F]%'),

    -- Foreign Key
    CONSTRAINT [FK_ServiceResponseFileEmbeddings_ServiceResponseFiles_ServiceResponseFileId]
        FOREIGN KEY ([ServiceResponseFileId]) REFERENCES [dbo].[ServiceResponseFiles]([Id]) ON DELETE CASCADE
)
GO

CREATE NONCLUSTERED INDEX [IX_ServiceResponseFileEmbeddings_ServiceResponseFileId]
    ON [dbo].[ServiceResponseFileEmbeddings]([ServiceResponseFileId] ASC)
GO

CREATE NONCLUSTERED INDEX [IX_ServiceResponseFileEmbeddings_FileName]
    ON [dbo].[ServiceResponseFileEmbeddings]([FileName] ASC)
GO

CREATE NONCLUSTERED INDEX [IX_ServiceResponseFileEmbeddings_FileFormat]
    ON [dbo].[ServiceResponseFileEmbeddings]([FileFormat] ASC)
