CREATE TABLE [dbo].[ServiceRequestFiles] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [OperationId] INT NOT NULL,
    [FileFormat] VARCHAR(10) NULL,
    [FileName] NVARCHAR(250) NOT NULL,
    [FileData] VARBINARY(MAX) NOT NULL,
    [UncompressedSizeBytes] INT NULL,
    [CompressionAlgorithmType] VARCHAR(50) NULL,
    [FileHash] VARCHAR(64) NULL,
    [RecordVersion] VARCHAR(50) NOT NULL
        CONSTRAINT DF_ServiceRequestFiles_RecordVersion DEFAULT ([dbo].[fn_CalculateVersion](NULL)),
    [IsActive] BIT NOT NULL CONSTRAINT DF_ServiceRequestFiles_IsActive DEFAULT 1,
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

CREATE NONCLUSTERED INDEX IX_ServiceRequestFiles_FileName
    ON [dbo].[ServiceRequestFiles]([FileName] ASC)
GO

CREATE NONCLUSTERED INDEX IX_ServiceRequestFiles_IsActive
    ON [dbo].[ServiceRequestFiles]([IsActive] ASC)
GO

CREATE NONCLUSTERED INDEX IX_ServiceRequestFiles_CreatedBy
    ON [dbo].[ServiceRequestFiles]([CreatedBy] ASC)
