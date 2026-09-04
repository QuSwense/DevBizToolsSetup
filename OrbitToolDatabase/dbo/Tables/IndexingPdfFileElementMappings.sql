/*
    Table: IndexingPdfFileElementMappings
    Description: Maps PDF file elements to their unique element references.
    Supports both request and response files.
*/
CREATE TABLE [dbo].[IndexingPdfFileElementMappings]
(
    -- Primary key.
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    -- Foreign Key target for BinaryEmbeddingsStore
    [BinaryEmbeddingsStoreId] INT NULL,
    -- Foreign Key referencing the unique entry in IndexingPdfFileElementSearch.
    [IndexingPdfFileElementSearchId] BIGINT NOT NULL,

    CONSTRAINT [PK_IndexingPdfFileElementMappings] 
        PRIMARY KEY CLUSTERED ([Id] ASC) 
        WITH (DATA_COMPRESSION = PAGE),

    CONSTRAINT [FK_IndexingPdfFileElementMappings_IndexingPdfFileElementSearch] 
        FOREIGN KEY ([IndexingPdfFileElementSearchId]) REFERENCES [dbo].[IndexingPdfFileElementSearch]([Id]) ON DELETE CASCADE,

    CONSTRAINT [FK_IndexingPdfFileElementMappings_BinaryEmbeddingsStore] 
        FOREIGN KEY ([BinaryEmbeddingsStoreId]) REFERENCES [dbo].[BinaryEmbeddingsStore]([Id])
);
GO
