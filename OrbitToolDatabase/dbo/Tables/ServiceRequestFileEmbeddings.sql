/*
    Table: ServiceRequestFileEmbeddings
    Description: Stores embeddings for service request files, including file data, format, compression details, and associated service request file or history.
*/
CREATE TABLE [dbo].[ServiceRequestFileEmbeddings] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Public Identifier for UI/Secure Operations (GUID)
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_ServiceRequestFileEmbeddings_PublicId DEFAULT NEWID(),
    -- Foreign Key to ServiceRequestFiles table (optional)
    [ServiceRequestFileId] INT NOT NULL,
    -- Foreign Key to IndexingXmlFileElements or IndexingJsonFileElements table as per the 
    -- [dbo].[ServiceRequestFiles].[FileFormat] of the associated service request file.
    -- which defines the location of the embedding within the file.
    [IndexingXmlFileElementId] INT NULL,
    [IndexingJsonFileElementId] INT NULL,
    -- Foreign Key to BinaryEmbeddingsStore table
    [BinaryEmbeddingsStoreId] INT NOT NULL,
    -- File name, e.g., 'response.xml', 'response.json'. Either custom name or original name extracted from the request.
    [Name] NVARCHAR(250) NOT NULL,
    -- Indicates if the service request file embedding record is currently active
    [IsActive] BIT NOT NULL CONSTRAINT DF_ServiceRequestFileEmbeddings_IsActive DEFAULT 1,
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME2(3) NOT NULL CONSTRAINT DF_ServiceRequestFileEmbeddings_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME2(3) NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT PK_ServiceRequestFileEmbeddings PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_ServiceRequestFileEmbeddings_PublicId UNIQUE ([PublicId] ASC),
    CONSTRAINT UQ_ServiceRequestFileEmbeddings_ServiceRequestFileId_BinaryEmbeddingsStoreId UNIQUE ([ServiceRequestFileId] ASC, [BinaryEmbeddingsStoreId] ASC),
    
    CONSTRAINT FK_ServiceRequestFileEmbeddings_ServiceRequestFiles
        FOREIGN KEY ([ServiceRequestFileId]) REFERENCES [dbo].[ServiceRequestFiles]([Id]),
    CONSTRAINT FK_ServiceRequestFileEmbeddings_IndexingXmlFileElement
        FOREIGN KEY ([IndexingXmlFileElementId]) REFERENCES [dbo].[IndexingXmlFileElements]([Id]),
    CONSTRAINT FK_ServiceRequestFileEmbeddings_IndexingJsonFileElement
        FOREIGN KEY ([IndexingJsonFileElementId]) REFERENCES [dbo].[IndexingJsonFileElements]([Id]),
    CONSTRAINT FK_ServiceRequestFileEmbeddings_BinaryEmbeddingsStore
        FOREIGN KEY ([BinaryEmbeddingsStoreId]) REFERENCES [dbo].[BinaryEmbeddingsStore]([Id]),
    CONSTRAINT FK_ServiceRequestFileEmbeddings_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_ServiceRequestFileEmbeddings_Users_LastUpdatedBy
        FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_ServiceRequestFileEmbeddings_ServiceRequestFileId]
    ON [dbo].[ServiceRequestFileEmbeddings]([ServiceRequestFileId] ASC)
GO

CREATE NONCLUSTERED INDEX [IX_ServiceRequestFileEmbeddings_BinaryEmbeddingsStoreId]
    ON [dbo].[ServiceRequestFileEmbeddings]([BinaryEmbeddingsStoreId] ASC)
GO

CREATE NONCLUSTERED INDEX [IX_ServiceRequestFileEmbeddings_Name]
    ON [dbo].[ServiceRequestFileEmbeddings]([Name] ASC)
GO