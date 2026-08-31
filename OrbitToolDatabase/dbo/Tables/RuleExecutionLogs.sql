/*
    Table: RuleExecutionLogs
    Description: Logs the execution of rules, including input context, success status, results, and any error messages.
    Logic: Each log entry is associated with a specific rule set and captures the execution context, result, and metadata for auditing purposes.
*/
CREATE TABLE [dbo].[RuleExecutionLogs] (
    -- Primary Key and Identity
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Foreign Key Reference to RuleSets
    [RuleSetId] INT NOT NULL,
    -- Input and Output Compressed Content
    [InputCompressedContent] VARBINARY(MAX) NOT NULL,
    [OutputCompressedContent] VARBINARY(MAX) NULL,
    -- Input and Output Uncompressed Size in bytes
    [InputUncompressedSizeBytes] INT NULL,
    [OutputUncompressedSizeBytes] INT NULL,
    -- compression algorithm used for the input content, e.g., 'Zstandard', 'Brotli', 'Gzip', 'none'
    [CompressionAlgorithmType] VARCHAR(50) NULL,
    -- SHA256 hash of the input content for integrity verification
    [InputContentHash] VARCHAR(64) NULL,
    [OutputContentHash] VARCHAR(64) NULL,
    [IsSuccess] BIT NOT NULL,
    [ErrorMessage] NVARCHAR(MAX) NULL,
    [ExecutionTimeMs] INT NULL,
    [ExecutedAt] DATETIME NOT NULL CONSTRAINT DF_RuleExecutionLogs_ExecutedAt DEFAULT GETDATE(),
    [ExecutedBy] NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_RuleExecutionLogs PRIMARY KEY CLUSTERED ([Id] ASC),

    CONSTRAINT CK_RuleExecutionLogs_CompressionAlgorithmType
        CHECK ([CompressionAlgorithmType] IS NULL OR [CompressionAlgorithmType] IN ('Zstandard', 'Brotli', 'Gzip', 'none')),
    CONSTRAINT CK_RuleExecutionLogs_InputContentHash
        CHECK ([InputContentHash] IS NULL OR LEN([InputContentHash]) = 64 AND [InputContentHash] NOT LIKE '%[^0-9a-fA-F]%'),
    CONSTRAINT CK_RuleExecutionLogs_OutputContentHash
        CHECK ([OutputContentHash] IS NULL OR LEN([OutputContentHash]) = 64 AND [OutputContentHash] NOT LIKE '%[^0-9a-fA-F]%'),

    CONSTRAINT FK_RuleExecutionLogs_RuleSets FOREIGN KEY ([RuleSetId])
        REFERENCES [dbo].[RuleSets]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_RuleExecutionLogs_Users_ExecutedBy
        FOREIGN KEY ([ExecutedBy]) REFERENCES [dbo].[Users]([UserId])
)
