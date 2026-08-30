/*
    Table: ServiceResponseFileEmbeddings
    Description: Stores embeddings for service response files, including file data, format, compression details, and associated service response file.
*/
CREATE TABLE [dbo].[ServiceResponseFileEmbeddings] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Foreign Key to ServiceResponseFiles table
    [ServiceResponseFileId] INT NOT NULL,
    -- string representing the file format, e.g., 'XML', 'JSON', 'PDF', 'BINARY'
    [FileFormat] VARCHAR(10) NULL,
    -- File name, e.g., 'response.xml', 'response.json'. Eitehr custom name or original name extracted from the request.
    [Name] NVARCHAR(250) NOT NULL,
    [CompressedData] VARBINARY(MAX) NOT NULL,
    -- Flattened minimized content of the file, can also be PDF. We use rules to extract the content from the file.
    [FlattenedContent] NVARCHAR(MAX) NOT NULL,
    -- Uncompressed size of the file in bytes
    [UncompressedSizeBytes] INT NULL,
    -- Compression algorithm used for the file, e.g., 'Zstandard', 'Brotli', 'Gzip', 'none'
    [CompressionAlgorithmType] VARCHAR(50) NULL,
    -- SHA256 hash of the file data for integrity verification
    [FileHash] VARCHAR(64) NULL,
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceResponseFileEmbeddings_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT [PK_ServiceResponseFileEmbeddings] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT CK_ServiceResponseFileEmbeddings_FileFormat
        CHECK ([FileFormat] IS NULL OR [FileFormat] IN ('XML','JSON','PDF','BINARY')),
    CONSTRAINT CK_ServiceResponseFileEmbeddings_CompressionAlgorithmType
        CHECK ([CompressionAlgorithmType] IS NULL OR [CompressionAlgorithmType] IN ('Zstandard', 'Brotli', 'Gzip', 'none')),
    CONSTRAINT CK_ServiceResponseFileEmbeddings_FileHash
        CHECK ([FileHash] IS NULL OR LEN([FileHash]) = 64 AND [FileHash] NOT LIKE '%[^0-9a-fA-F]%'),

    -- Foreign Key
    CONSTRAINT [FK_ServiceResponseFileEmbeddings_ServiceResponseFiles_ServiceResponseFileId]
        FOREIGN KEY ([ServiceResponseFileId]) REFERENCES [dbo].[ServiceResponseFiles]([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_ServiceResponseFileEmbeddings_Users_CreatedBy]
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT [FK_ServiceResponseFileEmbeddings_Users_LastUpdatedBy]
        FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
)
GO

CREATE NONCLUSTERED INDEX [IX_ServiceResponseFileEmbeddings_ServiceResponseFileId]
    ON [dbo].[ServiceResponseFileEmbeddings]([ServiceResponseFileId] ASC)
GO

CREATE NONCLUSTERED INDEX [IX_ServiceResponseFileEmbeddings_Name]
    ON [dbo].[ServiceResponseFileEmbeddings]([Name] ASC)
GO

CREATE NONCLUSTERED INDEX [IX_ServiceResponseFileEmbeddings_FileFormat]
    ON [dbo].[ServiceResponseFileEmbeddings]([FileFormat] ASC)
GO
