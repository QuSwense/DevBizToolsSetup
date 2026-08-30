/*
    Table: ServiceRequestFiles
    Description: Stores files associated with service requests, including file data, format, compression details, and associated service operation.
*/
CREATE TABLE [dbo].[ServiceRequestFiles] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Foreign Key to ServiceOperations table
    [OperationId] INT NOT NULL,
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
        CONSTRAINT DF_ServiceRequestFiles_RecordVersion DEFAULT ([dbo].[fn_CalculateVersion](NULL)),
    -- Indicates if the service request file record is currently active
    [IsActive] BIT NOT NULL CONSTRAINT DF_ServiceRequestFiles_IsActive DEFAULT 1,
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceRequestFiles_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT PK_ServiceRequestFiles PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT CK_ServiceRequestFiles_Format
        CHECK ([FileFormat] IS NULL OR [FileFormat] IN ('XML','JSON','PDF','BINARY')),
    CONSTRAINT CK_ServiceRequestFiles_CompressionAlgorithmType
        CHECK ([CompressionAlgorithmType] IS NULL OR [CompressionAlgorithmType] IN ('Zstandard', 'Brotli', 'Gzip', 'none')),
    CONSTRAINT CK_ServiceRequestFiles_FileHash
        CHECK ([FileHash] IS NULL OR LEN([FileHash]) = 64 AND [FileHash] NOT LIKE '%[^0-9a-fA-F]%'),
    CONSTRAINT CK_ServiceRequestFiles_RecordVersionFormat
        CHECK ([RecordVersion] LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9]'),

    -- Foreign keys
    CONSTRAINT FK_ServiceRequestFiles_ServiceOperations_OperationId
        FOREIGN KEY ([OperationId]) REFERENCES [dbo].[ServiceOperations]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceRequestFiles_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_ServiceRequestFiles_Users_LastUpdatedBy
        FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
)
GO

CREATE NONCLUSTERED INDEX IX_ServiceRequestFiles_OperationId
    ON [dbo].[ServiceRequestFiles]([OperationId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_ServiceRequestFiles_CreatedAt
    ON [dbo].[ServiceRequestFiles]([CreatedAt] ASC)
GO

CREATE NONCLUSTERED INDEX IX_ServiceRequestFiles_Name
    ON [dbo].[ServiceRequestFiles]([Name] ASC)
GO

CREATE NONCLUSTERED INDEX IX_ServiceRequestFiles_IsActive
    ON [dbo].[ServiceRequestFiles]([IsActive] ASC)
GO

CREATE NONCLUSTERED INDEX IX_ServiceRequestFiles_CreatedBy
    ON [dbo].[ServiceRequestFiles]([CreatedBy] ASC)
GO
