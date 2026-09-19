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
CREATE TABLE [dbo].[BinaryEmbeddingStores] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    -- Public Identifier for UI/Secure Operations (GUID)
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT [DF_BinaryEmbeddingStores_PublicId] DEFAULT NEWID(),
    -- A key name which is used to reference the binary content in an XML or JSON file
    [KeyName] NVARCHAR(255) NOT NULL,
    -- Compressed physical byte stream of the binary attachment.
    [CompressedData] VARBINARY(MAX) NOT NULL,
    -- Original uncompressed byte size of the binary asset.
    [UncompressedSizeBytes] BIGINT NOT NULL,
    -- Compression algorithm applied prior to storage (e.g., 'Zstandard', 'Brotli', 'Gzip', 'none').
    [CompressionAlgorithmType] NVARCHAR(50) NULL,
    -- File extension or format classification (e.g., 'PDF', 'BINARY').
    [ContentFormat] NVARCHAR(10) NULL,
    -- Additional file type general metadata if there are any for a binary content
    [AdditionalDetails] NVARCHAR(MAX) NULL,
    -- Record version for optimistic concurrency control, formatted as 'YY.QQ.NN', e.g., '24.10.01'
    [RecordVersion] VARCHAR(50) NOT NULL
        CONSTRAINT [DF_BinaryEmbeddingStores_RecordVersion] DEFAULT ([dbo].[fn_CalculateVersion](NULL)),
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME2(3) NOT NULL CONSTRAINT [DF_BinaryEmbeddingStores_CreatedAt] DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME2(3) NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT [PK_BinaryEmbeddingStores] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ_BinaryEmbeddingStores_PublicId] UNIQUE ([PublicId] ASC),
    CONSTRAINT [CK_BinaryEmbeddingStores_Format] CHECK ([ContentFormat] IS NULL OR [ContentFormat] IN ('XML', 'JSON', 'PDF','BINARY')),
    CONSTRAINT [CK_BinaryEmbeddingStores_Compression] CHECK ([CompressionAlgorithmType] IS NULL OR [CompressionAlgorithmType] IN ('Zstandard', 'Brotli', 'Gzip', 'none')),
    CONSTRAINT [CK_BinaryEmbeddingStores_RecordVersionFormat]
        CHECK ([RecordVersion] LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9]'),

    CONSTRAINT [FK_BinaryEmbeddingStores_Users_CreatedBy]
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT [FK_BinaryEmbeddingStores_Users_LastUpdatedBy]
        FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
);
GO