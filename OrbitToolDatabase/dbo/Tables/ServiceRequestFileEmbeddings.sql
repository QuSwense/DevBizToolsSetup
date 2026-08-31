/*
    Table: ServiceRequestFileEmbeddings
    Description: Stores embeddings for service request files, including file data, format, compression details, and associated service request file or history.
*/
CREATE TABLE [dbo].[ServiceRequestFileEmbeddings] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Foreign Key to ServiceRequestFiles table (optional)
    [ServiceRequestFileId] INT NOT NULL,
    -- Foreign Key to BinaryEmbeddingsStore table
    [BinaryEmbeddingsStoreId] INT NOT NULL,
    -- File name, e.g., 'response.xml', 'response.json'. Either custom name or original name extracted from the request.
    [Name] NVARCHAR(250) NOT NULL,
    -- Foreign Key referencing the deduplicated binary vault record in BinaryEmbeddingsStore.
    [FileHash] VARCHAR(64) NOT NULL,
    -- Indicates if the service request file embedding record is currently active
    [IsActive] BIT NOT NULL CONSTRAINT DF_ServiceRequestFileEmbeddings_IsActive DEFAULT 1,
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceRequestFileEmbeddings_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT PK_ServiceRequestFileEmbeddings PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_ServiceRequestFileEmbeddings_ServiceRequestFileId_BinaryEmbeddingsStoreId UNIQUE ([ServiceRequestFileId] ASC, [BinaryEmbeddingsStoreId] ASC),
    
    CONSTRAINT CK_ServiceRequestFileEmbeddings_FileHash
        CHECK ([FileHash] IS NULL OR LEN([FileHash]) = 64 AND [FileHash] NOT LIKE '%[^0-9a-fA-F]%'),

    CONSTRAINT FK_ServiceRequestFileEmbeddings_ServiceRequestFiles
        FOREIGN KEY ([ServiceRequestFileId]) REFERENCES [dbo].[ServiceRequestFiles]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceRequestFileEmbeddings_BinaryEmbeddingsStore
        FOREIGN KEY ([BinaryEmbeddingsStoreId]) REFERENCES [dbo].[BinaryEmbeddingsStore]([Id]),
    CONSTRAINT FK_ServiceRequestFileEmbeddings_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_ServiceRequestFileEmbeddings_Users_LastUpdatedBy
        FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
);
GO