/*
    Table: IndexingJsonFileElementValues
    Description: Search view specifically for JSON elements.
    Denormalized for faster searching across JSON element types.
*/
CREATE TABLE [dbo].[IndexingJsonFileElementValues]
(
    -- Primary Key
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    -- Element reference
    [IndexingJsonFileElementId] BIGINT NOT NULL,
    -- Path and value
    [ElementValue] NVARCHAR(1024) NOT NULL,
    [CreatedAt] DATETIME2(3) NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT [PK_IndexingJsonFileElementValues] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (DATA_COMPRESSION = PAGE),

    CONSTRAINT [FK_IndexingJsonFileElementValues_IndexingJsonFileElements] 
        FOREIGN KEY ([IndexingJsonFileElementId]) REFERENCES [dbo].[IndexingJsonFileElements]([Id])
);
GO

CREATE NONCLUSTERED INDEX [IX_IndexingJsonFileElementValues_ElementId]
    ON [dbo].[IndexingJsonFileElementValues]([IndexingJsonFileElementId] ASC)
GO
