/*
    Table: ServiceResponseFileEmbeddings
    Description: Stores embeddings for service response files, including file data, format, compression details, and associated service response file.
*/
CREATE TABLE [dbo].[ServiceResponseFileEmbeddings] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Foreign Key to ServiceResponseFiles table
    [ServiceResponseFileId] INT NOT NULL,
    -- Foreign Key to BinaryEmbeddingsStore table
    [BinaryEmbeddingsStoreId] INT NOT NULL,
    -- File name, e.g., 'response.xml', 'response.json'. Either custom name or original name extracted from the request.
    [Name] NVARCHAR(250) NOT NULL,
    -- Foreign Key referencing the deduplicated binary vault record in BinaryEmbeddingsStore.
    [FileHash] VARCHAR(64) NOT NULL,
    -- Indicates if the service response file embedding record is currently active
    [IsActive] BIT NOT NULL CONSTRAINT DF_ServiceResponseFileEmbeddings_IsActive DEFAULT 1,
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceResponseFileEmbeddings_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT [PK_ServiceResponseFileEmbeddings] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_ServiceResponseFileEmbeddings_ServiceResponseFileId_BinaryEmbeddingsStoreId UNIQUE ([ServiceResponseFileId] ASC, [BinaryEmbeddingsStoreId] ASC),

    CONSTRAINT CK_ServiceResponseFileEmbeddings_FileHash
        CHECK ([FileHash] IS NULL OR LEN([FileHash]) = 64 AND [FileHash] NOT LIKE '%[^0-9a-fA-F]%'),

    -- Foreign Key
    CONSTRAINT [FK_ServiceResponseFileEmbeddings_ServiceResponseFiles_ServiceResponseFileId]
        FOREIGN KEY ([ServiceResponseFileId]) REFERENCES [dbo].[ServiceResponseFiles]([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_ServiceResponseFileEmbeddings_BinaryEmbeddingsStore]
        FOREIGN KEY ([BinaryEmbeddingsStoreId]) REFERENCES [dbo].[BinaryEmbeddingsStore]([Id]),
    CONSTRAINT [FK_ServiceResponseFileEmbeddings_Users_CreatedBy]
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT [FK_ServiceResponseFileEmbeddings_Users_LastUpdatedBy]
        FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
)
GO

CREATE NONCLUSTERED INDEX [IX_ServiceResponseFileEmbeddings_ServiceResponseFileId]
    ON [dbo].[ServiceResponseFileEmbeddings]([ServiceResponseFileId] ASC)
GO

CREATE NONCLUSTERED INDEX [IX_ServiceResponseFileEmbeddings_Name]
    ON [dbo].[ServiceResponseFileEmbeddings]([Name] ASC)
GO
