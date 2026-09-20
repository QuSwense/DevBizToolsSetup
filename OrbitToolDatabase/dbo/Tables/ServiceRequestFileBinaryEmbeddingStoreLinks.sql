/*
    Table: ServiceRequestFileBinaryEmbeddingStoreLinks
    Description: Stores embeddings for service request files, including file data, format, compression details, and associated service request file or history.
*/
CREATE TABLE [dbo].[ServiceRequestFileBinaryEmbeddingStoreLinks] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Public Identifier for UI/Secure Operations (GUID)
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_ServiceRequestFileBinaryEmbeddingStoreLinks_PublicId DEFAULT NEWID(),
    -- Foreign Key to ServiceRequestFiles table (optional)
    [ServiceRequestFileId] INT NOT NULL,
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
    [CreatedAt] DATETIME2(3) NOT NULL CONSTRAINT DF_ServiceRequestFileBinaryEmbeddingStoreLinks_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_ServiceRequestFileBinaryEmbeddingStoreLinks PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_ServiceRequestFileBinaryEmbeddingStoreLinks_PublicId UNIQUE ([PublicId] ASC),
    CONSTRAINT UQ_ServiceRequestFileBinaryEmbeddingStoreLinks_ServiceRequestFileId_BinaryEmbeddingsStoreId UNIQUE ([ServiceRequestFileId] ASC, [BinaryEmbeddingsStoreId] ASC),
    
    CONSTRAINT FK_ServiceRequestFileBinaryEmbeddingStoreLinks_ServiceRequestFiles
        FOREIGN KEY ([ServiceRequestFileId]) REFERENCES [dbo].[ServiceRequestFiles]([Id]),
    CONSTRAINT FK_ServiceRequestFileBinaryEmbeddingStoreLinks_BinaryEmbeddingStores
        FOREIGN KEY ([BinaryEmbeddingsStoreId]) REFERENCES [dbo].[BinaryEmbeddingStores]([Id]),
    CONSTRAINT FK_ServiceRequestFileBinaryEmbeddingStoreLinks_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_ServiceRequestFileBinaryEmbeddingStoreLinks_ServiceRequestFileId]
    ON [dbo].[ServiceRequestFileBinaryEmbeddingStoreLinks]([ServiceRequestFileId] ASC)
GO

CREATE NONCLUSTERED INDEX [IX_ServiceRequestFileBinaryEmbeddingStoreLinks_BinaryEmbeddingsStoreId]
    ON [dbo].[ServiceRequestFileBinaryEmbeddingStoreLinks]([BinaryEmbeddingsStoreId] ASC)
GO

CREATE NONCLUSTERED INDEX [IX_ServiceRequestFileBinaryEmbeddingStoreLinks_Name]
    ON [dbo].[ServiceRequestFileBinaryEmbeddingStoreLinks]([Name] ASC)
GO