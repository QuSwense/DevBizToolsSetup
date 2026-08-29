-- Populated only via trg_ServiceRequestFiles_Audit
CREATE TABLE [dbo].[ServiceRequestFileHistorys] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [ServiceRequestFileId] INT NOT NULL,
    [FileFormat] VARCHAR(10) NULL,
    [FileName] NVARCHAR(250) NOT NULL,
    [FileData] VARBINARY(MAX) NOT NULL,
    [UncompressedSizeBytes] INT NULL,
    [CompressionAlgorithmType] VARCHAR(50) NULL,
    [FileHash] VARCHAR(64) NULL,
    [RecordVersion] VARCHAR(50) NOT NULL,
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
