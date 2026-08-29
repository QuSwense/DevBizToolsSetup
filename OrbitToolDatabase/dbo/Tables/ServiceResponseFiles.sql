CREATE TABLE [dbo].[ServiceResponseFiles] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [FileFormat] VARCHAR(10) NULL,
    [FileName] NVARCHAR(250) NOT NULL,
    [FileData] VARBINARY(MAX) NOT NULL,
    [UncompressedSizeBytes] INT NULL,
    [CompressionAlgorithmType] VARCHAR(50) NULL,
    [FileHash] VARCHAR(64) NULL,
    [CreatedAt] DATETIME NOT NULL
        CONSTRAINT DF_ServiceResponseFiles_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_ServiceResponseFiles PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT CK_ServiceResponseFiles_Format
        CHECK ([FileFormat] IS NULL OR [FileFormat] IN ('XML','JSON','PDF','BINARY')),
    CONSTRAINT CK_ServiceResponseFiles_CompressionAlgorithmType
        CHECK ([CompressionAlgorithmType] IS NULL OR [CompressionAlgorithmType] IN ('Zstandard', 'Brotli', 'Gzip', 'none')),
    CONSTRAINT CK_ServiceResponseFiles_FileHash
        CHECK ([FileHash] IS NULL OR LEN([FileHash]) = 64 AND [FileHash] NOT LIKE '%[^0-9a-fA-F]%'),

    -- Foreign Key Constraint
    CONSTRAINT FK_ServiceResponseFiles_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId])
)
