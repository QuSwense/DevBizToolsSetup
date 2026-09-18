/*
    Table: IndexingPdfFileElementValues
    Description: Search view specifically for PDF elements.
    Denormalized for faster searching across PDF element types.
*/
CREATE TABLE [dbo].[IndexingPdfFileElementValues]
(
    -- Primary Key
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    -- Element reference
    [IndexingPdfFileElementId] BIGINT NOT NULL,
    -- Path and value
    [ElementValue] NVARCHAR(800) NOT NULL,
    [CreatedAt] DATETIME2(3) NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT [PK_IndexingPdfFileElementValues] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (DATA_COMPRESSION = PAGE),

    CONSTRAINT [FK_IndexingPdfFileElementValues_IndexingPdfFileElements] 
        FOREIGN KEY ([IndexingPdfFileElementId]) REFERENCES [dbo].[IndexingPdfFileElements]([Id])
);
GO

CREATE NONCLUSTERED INDEX [IX_IndexingPdfFileElementValues_ElementId]
    ON [dbo].[IndexingPdfFileElementValues]([IndexingPdfFileElementId] ASC)
GO
