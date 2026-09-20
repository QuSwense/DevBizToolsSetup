/*
    Table: ServiceResponseFileBinaryEmbeddingStoreLinks
    Description: Stores embeddings for service response files, including file data, format, compression details, and associated service response file or history.
*/
CREATE TABLE [dbo].[ServiceResponseFileBinaryEmbeddingStoreLinks] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Public Identifier for UI/Secure Operations (GUID)
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_ServiceResponseFileBinaryEmbeddingStoreLinks_PublicId DEFAULT NEWID(),
    -- Foreign Key to ServiceResponseFiles table (optional)
    [ServiceResponseFileId] BIGINT NOT NULL,
    -- Primary Key, auto-incrementing identity integer.
    [ElementName] NVARCHAR(400) NOT NULL,
    -- XML Path key path, using XPath in C#
    [XmlPath] NVARCHAR(400) NOT NULL,
    -- Foreign Key to BinaryEmbeddingStores table
    [BinaryEmbeddingsStoreId] BIGINT NOT NULL,
    -- File name, e.g., 'response.xml', 'response.json'. Either custom name or original name extracted from the request.
    [Name] NVARCHAR(250) NOT NULL,
    -- Additional file type general metadata if there are any for a binary content
    [AdditionalDetails] NVARCHAR(MAX) NULL,
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME2(3) NOT NULL CONSTRAINT DF_ServiceResponseFileBinaryEmbeddingStoreLinks_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_ServiceResponseFileBinaryEmbeddingStoreLinks PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_ServiceResponseFileBinaryEmbeddingStoreLinks_PublicId UNIQUE ([PublicId] ASC),
    CONSTRAINT UQ_ServiceResponseFileBinaryEmbeddingStoreLinks_ServiceResponseFileId_BinaryEmbeddingsStoreId UNIQUE ([ServiceResponseFileId] ASC, [BinaryEmbeddingsStoreId] ASC),
    
    CONSTRAINT FK_ServiceResponseFileBinaryEmbeddingStoreLinks_ServiceResponseFiles
        FOREIGN KEY ([ServiceResponseFileId]) REFERENCES [dbo].[ServiceResponseFiles]([Id]),
    CONSTRAINT FK_ServiceResponseFileBinaryEmbeddingStoreLinks_BinaryEmbeddingStores
        FOREIGN KEY ([BinaryEmbeddingsStoreId]) REFERENCES [dbo].[BinaryEmbeddingStores]([Id]),
    CONSTRAINT FK_ServiceResponseFileBinaryEmbeddingStoreLinks_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_ServiceResponseFileBinaryEmbeddingStoreLinks_ServiceResponseFileId]
    ON [dbo].[ServiceResponseFileBinaryEmbeddingStoreLinks]([ServiceResponseFileId] ASC)
GO

CREATE NONCLUSTERED INDEX [IX_ServiceResponseFileBinaryEmbeddingStoreLinks_BinaryEmbeddingsStoreId]
    ON [dbo].[ServiceResponseFileBinaryEmbeddingStoreLinks]([BinaryEmbeddingsStoreId] ASC)
GO

CREATE NONCLUSTERED INDEX [IX_ServiceResponseFileBinaryEmbeddingStoreLinks_Name]
    ON [dbo].[ServiceResponseFileBinaryEmbeddingStoreLinks]([Name] ASC)
GO