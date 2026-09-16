/*
    Table: IndexingJsonFileElementSearch
    Description: Search view specifically for JSON elements.
    Denormalized for faster searching across JSON element types.
*/
CREATE TABLE [dbo].[IndexingJsonFileElementSearch]
(
    -- Primary Key
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    -- Element reference
    [IndexingJsonFileElementId] BIGINT NOT NULL,
    -- Path and value
    [ElementValue] NVARCHAR(1024) NOT NULL,
    [CreatedAt] DATETIME2(3) NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT [PK_IndexingJsonFileElementSearch] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (DATA_COMPRESSION = PAGE),

    CONSTRAINT [FK_IndexingJsonFileElementSearch_IndexingJsonFileElements] 
        FOREIGN KEY ([IndexingJsonFileElementId]) REFERENCES [dbo].[IndexingJsonFileElements]([Id])
);
GO

CREATE NONCLUSTERED INDEX [IX_IndexingJsonFileElementSearch_ElementId]
    ON [dbo].[IndexingJsonFileElementSearch]([IndexingJsonFileElementId] ASC)
GO
