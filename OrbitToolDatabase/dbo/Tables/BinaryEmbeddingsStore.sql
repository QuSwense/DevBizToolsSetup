/*
    This table is designed to store binary data (e.g., files, attachments) in a content-addressable manner. Each unique piece of content is stored only once, identified by its SHA-256 hash. This approach reduces storage redundancy and allows for efficient retrieval of binary data based on its content hash.

    Key Features:
    - Content Hashing: Each binary file is hashed using SHA-256 to create a unique identifier for the content.
    - Compression: Binary data can be stored in a compressed format to save space. The compression algorithm used is recorded for decompression purposes.
    - Content Format: The format of the content (e.g., XML, JSON, PDF, BINARY) can be specified for better categorization and processing.
    - Auditing: Timestamps are recorded for when each entry is created, allowing for tracking and auditing of stored content.

    Usage:
    - When a new binary file is to be stored, its SHA-256 hash is computed. If an entry with that hash already exists, the existing entry can be reused instead of storing a duplicate.
    - The table supports various compression algorithms, allowing for flexibility in how binary data is stored and retrieved.

*/
CREATE TABLE [dbo].[BinaryEmbeddingsStore] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Primary Key: SHA-256 hash calculated over the raw binary content for global single-instance deduplication.
    [FileHash] VARCHAR(64) NOT NULL,
    -- Compressed physical byte stream of the binary attachment.
    [CompressedData] VARBINARY(MAX) NOT NULL,
    -- Original uncompressed byte size of the binary asset.
    [UncompressedSizeBytes] INT NOT NULL,
    -- Compression algorithm applied prior to storage (e.g., 'Zstandard', 'Brotli', 'Gzip', 'none').
    [CompressionAlgorithmType] VARCHAR(50) NOT NULL,
    -- File extension or format classification (e.g., 'PDF', 'BINARY').
    [FileFormat] VARCHAR(10) NULL,
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME NOT NULL CONSTRAINT [DF_BinaryEmbeddingsStore_CreatedAt] DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT [PK_BinaryEmbeddingsStore] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [CK_BinaryEmbeddingsStore_Format] CHECK ([FileFormat] IS NULL OR [FileFormat] IN ('XML','JSON','PDF','BINARY')),
    CONSTRAINT [CK_BinaryEmbeddingsStore_FileHash] CHECK (LEN([FileHash]) = 64 AND [FileHash] NOT LIKE '%[^0-9a-fA-F]%'),
    CONSTRAINT [CK_BinaryEmbeddingsStore_Compression] CHECK ([CompressionAlgorithmType] IN ('Zstandard', 'Brotli', 'Gzip', 'none')),

    CONSTRAINT [FK_BinaryEmbeddingsStore_Users_CreatedBy]
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT [FK_BinaryEmbeddingsStore_Users_LastUpdatedBy]
        FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
);
GO