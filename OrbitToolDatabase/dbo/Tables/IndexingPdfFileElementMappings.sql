/*
    Table: IndexingPdfFileElementMappings
    Description: Maps PDF file elements to their unique element references.
    Supports both request and response files.
*/
CREATE TABLE [dbo].[IndexingPdfFileElementMappings]
(
    -- Primary key.
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    -- Foreign Key target for BinaryEmbeddingStores
    [BinaryEmbeddingsStoreId] BIGINT NOT NULL,
    -- Foreign Key referencing the unique entry in IndexingPdfFileElementSearch.
    [IndexingPdfFileElementValueId] BIGINT NOT NULL,
    [CreatedAt] DATETIME2(3) NOT NULL DEFAULT GETDATE(),

    CONSTRAINT [PK_IndexingPdfFileElementMappings] 
        PRIMARY KEY CLUSTERED ([Id] ASC) 
        WITH (DATA_COMPRESSION = PAGE),

    CONSTRAINT [FK_IndexingPdfFileElementMappings_IndexingPdfFileElementValues] 
        FOREIGN KEY ([IndexingPdfFileElementValueId]) REFERENCES [dbo].[IndexingPdfFileElementValues]([Id]),

    CONSTRAINT [FK_IndexingPdfFileElementMappings_BinaryEmbeddingStores] 
        FOREIGN KEY ([BinaryEmbeddingsStoreId]) REFERENCES [dbo].[BinaryEmbeddingStores]([Id])
);
GO

CREATE NONCLUSTERED INDEX [IX_IndexingPdfFileElementMappings_BinaryEmbeddingsStoreId]
    ON [dbo].[IndexingPdfFileElementMappings]([BinaryEmbeddingsStoreId] ASC)
GO

CREATE NONCLUSTERED INDEX [IX_IndexingPdfFileElementMappings_ValueId]
    ON [dbo].[IndexingPdfFileElementMappings]([IndexingPdfFileElementValueId] ASC)
GO
