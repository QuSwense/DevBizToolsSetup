/*
    Table: ServiceRequestFiles
    Description: Stores files associated with service requests, including file data, format, compression details, and associated service operation.
*/
CREATE TABLE [dbo].[ServiceRequestFiles] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Public Identifier for UI/Secure Operations (GUID)
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_ServiceRequestFiles_PublicId DEFAULT NEWID(),
    -- Foreign Key to ServiceOperations table
    [ServiceOperationId] INT NOT NULL,
    -- File format, e.g., 'XML', 'JSON', 'PDF', 'BINARY'
    [FileFormat] VARCHAR(10) NULL,
    -- File name, as uploaded by the user
    [Name] NVARCHAR(250) NOT NULL,
    -- Compressed file data without any embedded binary data Base64 encoded which is stored in [ServiceRequestFileEmbeddings]
    [CompressedData] VARBINARY(MAX) NOT NULL,
    -- Uncompressed size of the file in bytes but is formated in a sepcific way like without whitespace,
    -- comments, and other non-essential characters
    [UncompressedSizeBytes] BIGINT NULL,
    -- Compression algorithm used for the file, e.g., 'Zstandard', 'Brotli', 'Gzip', 'none'
    [CompressionAlgorithmType] VARCHAR(50) NULL,
    -- Record version for optimistic concurrency control, formatted as 'YY.QQ.NN', e.g., '24.10.01'
    [RecordVersion] VARCHAR(50) NOT NULL
        CONSTRAINT DF_ServiceRequestFiles_RecordVersion DEFAULT ([dbo].[fn_CalculateVersion](NULL)),
    -- Indicates if the service request file record is currently active
    [IsActive] BIT NOT NULL CONSTRAINT DF_ServiceRequestFiles_IsActive DEFAULT 1,
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME2(3) NOT NULL CONSTRAINT DF_ServiceRequestFiles_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME2(3) NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT PK_ServiceRequestFiles PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_ServiceRequestFiles_PublicId UNIQUE ([PublicId] ASC),

    CONSTRAINT CK_ServiceRequestFiles_Format
        CHECK ([FileFormat] IS NULL OR [FileFormat] IN ('XML','JSON','PDF','BINARY')),
    CONSTRAINT CK_ServiceRequestFiles_CompressionAlgorithmType
        CHECK ([CompressionAlgorithmType] IS NULL OR [CompressionAlgorithmType] IN ('Zstandard', 'Brotli', 'Gzip', 'none')),
    CONSTRAINT CK_ServiceRequestFiles_RecordVersionFormat
        CHECK ([RecordVersion] LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9]'),

    -- Foreign keys
    CONSTRAINT FK_ServiceRequestFiles_ServiceOperations_ServiceOperationId
        FOREIGN KEY ([ServiceOperationId]) REFERENCES [dbo].[ServiceOperations]([Id]),
    CONSTRAINT FK_ServiceRequestFiles_ParentBaseId
        FOREIGN KEY ([ParentBaseId]) REFERENCES [dbo].[ServiceRequestFiles]([Id]),
    CONSTRAINT FK_ServiceRequestFiles_ParentDeltaId
        FOREIGN KEY ([ParentDeltaId]) REFERENCES [dbo].[ServiceRequestFiles]([Id]),
    CONSTRAINT FK_ServiceRequestFiles_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_ServiceRequestFiles_Users_LastUpdatedBy
        FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
);
GO

-- Uniqueness: name+version is unique per parent operation (the previous constraint keyed
-- on the nullable ParentBaseId/ParentDeltaId, which never enforced anything for base rows).
CREATE UNIQUE NONCLUSTERED INDEX IX_ServiceRequestFiles_Operation_Name_Version
    ON [dbo].[ServiceRequestFiles]([ServiceOperationId] ASC, [Name] ASC, [RecordVersion] ASC)
GO

CREATE NONCLUSTERED INDEX IX_ServiceRequestFiles_ServiceOperationId
    ON [dbo].[ServiceRequestFiles]([ServiceOperationId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_ServiceRequestFiles_ParentBaseId
    ON [dbo].[ServiceRequestFiles]([ParentBaseId] ASC)
GO

CREATE NONCLUSTERED INDEX IX_ServiceRequestFiles_ParentDeltaId
    ON [dbo].[ServiceRequestFiles]([ParentDeltaId] ASC)
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
