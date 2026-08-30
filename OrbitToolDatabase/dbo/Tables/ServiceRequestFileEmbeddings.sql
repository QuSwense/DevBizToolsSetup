/*
    Table: ServiceRequestFileEmbeddings
    Description: Stores embeddings for service request files, including file data, format, compression details, and associated service request file or history.
*/
CREATE TABLE [dbo].[ServiceRequestFileEmbeddings] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Foreign Key to ServiceRequestFiles table (optional)
    [ServiceRequestFileId] INT NULL,
    -- Foreign Key to ServiceRequestFileHistorys table (optional)
    [ServiceRequestFileHistoryId] INT NULL,
    -- File format, e.g., 'XML', 'JSON', 'PDF', 'BINARY'
    [FileFormat] VARCHAR(10) NULL,
    -- File name, e.g., 'request.xml', 'response.json'
    [Name] NVARCHAR(250) NOT NULL,
    -- Compressed file data
    [CompressedData] VARBINARY(MAX) NOT NULL,
    -- Flattened minimized content of the file, e.g., for XML or JSON files, this could be a single-line representation of the content. Stripped of whitespace and line breaks for easier searching and indexing. Any sensitive information should be removed or masked in this field to ensure privacy and security. Any file data embedded is stripped out. use rules atatched to the application to determine what is sensitive and should be removed or masked.
    [FlattenedContent] NVARCHAR(MAX) NOT NULL,
    -- Uncompressed size of the file in bytes
    [UncompressedSizeBytes] INT NULL,
    -- Compression algorithm used for the file, e.g., 'Zstandard', 'Brotli', 'Gzip', 'none'
    [CompressionAlgorithmType] VARCHAR(50) NULL,
    -- SHA256 hash of the file data for integrity verification
    [FileHash] VARCHAR(64) NULL,
    -- Record version for optimistic concurrency control, formatted as 'YY.QQ.NN', e.g., '24.10.01'
    [RecordVersion] VARCHAR(50) NOT NULL
        CONSTRAINT DF_ServiceRequestFileEmbeddings_RecordVersion DEFAULT ([dbo].[fn_CalculateVersion](NULL)),
    -- Indicates if the service request file embedding record is currently active
    [IsActive] BIT NOT NULL CONSTRAINT DF_ServiceRequestFileEmbeddings_IsActive DEFAULT 1,
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceRequestFileEmbeddings_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

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
        FOREIGN KEY ([ServiceRequestFileHistoryId]) REFERENCES [dbo].[ServiceRequestFileHistorys]([Id]),
    CONSTRAINT FK_ServiceRequestFileEmbeddings_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_ServiceRequestFileEmbeddings_Users_LastUpdatedBy
        FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
)
