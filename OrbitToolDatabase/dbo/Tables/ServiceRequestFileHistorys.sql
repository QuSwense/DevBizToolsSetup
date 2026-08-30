/*
    Table: ServiceRequestFileHistorys
    Description: Stores historical versions of service request files, including file data, format, compression details, and associated service request file. Populated only via trg_ServiceRequestFiles_Audit
*/
CREATE TABLE [dbo].[ServiceRequestFileHistorys] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Foreign Key to ServiceRequestFiles table
    [ServiceRequestFileId] INT NOT NULL,
    -- string representing the file format, e.g., 'XML', 'JSON', 'PDF', 'BINARY'
    [FileFormat] VARCHAR(10) NULL,
    -- File name, e.g., 'request.xml', 'request.json'. Either custom name or original name extracted from the request.
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
    [RecordVersion] VARCHAR(50) NOT NULL,
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceRequestFileHistorys_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT PK_ServiceRequestFileHistorys PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT CK_ServiceRequestFileHistorys_FileFormat
        CHECK ([FileFormat] IS NULL OR [FileFormat] IN ('XML','JSON','PDF','BINARY')),
    CONSTRAINT CK_ServiceRequestFileHistorys_CompressionAlgorithmType
        CHECK ([CompressionAlgorithmType] IS NULL OR [CompressionAlgorithmType] IN ('Zstandard', 'Brotli', 'Gzip', 'none')),
    CONSTRAINT CK_ServiceRequestFileHistorys_FileHash
        CHECK ([FileHash] IS NULL OR LEN([FileHash]) = 64 AND [FileHash] NOT LIKE '%[^0-9a-fA-F]%'),
    CONSTRAINT CK_ServiceRequestFileHistorys_RecordVersionFormat
        CHECK ([RecordVersion] LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9]'),

    -- Foreign keys
    CONSTRAINT FK_ServiceRequestFileHistorys_ServiceRequestFiles_ServiceRequestFileId
        FOREIGN KEY ([ServiceRequestFileId]) REFERENCES [dbo].[ServiceRequestFiles]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceRequestFileHistorys_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_ServiceRequestFileHistorys_Users_LastUpdatedBy
        FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
)
GO

CREATE NONCLUSTERED INDEX IX_ServiceRequestFileHistorys_ServiceRequestFileId
    ON [dbo].[ServiceRequestFileHistorys]([ServiceRequestFileId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_ServiceRequestFileHistorys_CreatedAt
    ON [dbo].[ServiceRequestFileHistorys]([CreatedAt] ASC)
GO

CREATE NONCLUSTERED INDEX IX_ServiceRequestFileHistorys_CreatedBy
    ON [dbo].[ServiceRequestFileHistorys]([CreatedBy] ASC)
