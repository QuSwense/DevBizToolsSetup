/*
    Table: IndexingXmlFileElementSearch
    Description: Search view specifically for XML elements.
    Denormalized for faster searching across XML element types.
*/
CREATE TABLE [dbo].[IndexingXmlFileElementSearch]
(
    -- Primary Key
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    -- Element reference
    [IndexingXmlFileElementId] BIGINT NOT NULL,
    -- Path and value
    [ElementValue] NVARCHAR(800) NOT NULL,
    [CreatedAt] DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT [PK_IndexingXmlFileElementSearch] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (DATA_COMPRESSION = PAGE),

    CONSTRAINT [FK_IndexingXmlFileElementSearch_IndexingXmlFileElements] 
        FOREIGN KEY ([IndexingXmlFileElementId]) REFERENCES [dbo].[IndexingXmlFileElements]([Id]) ON DELETE CASCADE
);
GO
