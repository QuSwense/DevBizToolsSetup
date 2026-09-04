/*
    Table: IndexingPdfFileElementSearch
    Description: Search view specifically for PDF elements.
    Denormalized for faster searching across PDF element types.
*/
CREATE TABLE [dbo].[IndexingPdfFileElementSearch]
(
    -- Primary Key
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    -- Element reference
    [IndexingPdfFileElementId] BIGINT NOT NULL,
    -- Path and value
    [ElementValue] NVARCHAR(800) NOT NULL,
    [CreatedAt] DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT [PK_IndexingPdfFileElementSearch] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (DATA_COMPRESSION = PAGE),

    CONSTRAINT [FK_IndexingPdfFileElementSearch_IndexingPdfFileElements] 
        FOREIGN KEY ([IndexingPdfFileElementId]) REFERENCES [dbo].[IndexingPdfFileElements]([Id]) ON DELETE CASCADE
);
GO
