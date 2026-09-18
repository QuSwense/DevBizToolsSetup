/*
    Table: IndexingXmlFileElementValues
    Description: Stores the actual values of XML file elements.
    Denormalized for faster searching across XML element types.
*/
CREATE TABLE [dbo].[IndexingXmlFileElementValues]
(
    -- Primary Key
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    -- Element reference
    [IndexingXmlFileElementId] BIGINT NOT NULL,
    -- Path and value
    [ElementValue] NVARCHAR(800) NOT NULL,
    [CreatedAt] DATETIME2(3) NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT [PK_IndexingXmlFileElementValues] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (DATA_COMPRESSION = PAGE),

    CONSTRAINT [FK_IndexingXmlFileElementValues_IndexingXmlFileElements] 
        FOREIGN KEY ([IndexingXmlFileElementId]) REFERENCES [dbo].[IndexingXmlFileElements]([Id])
);
GO

CREATE NONCLUSTERED INDEX [IX_IndexingXmlFileElementValues_ElementId]
    ON [dbo].[IndexingXmlFileElementValues]([IndexingXmlFileElementId] ASC)
GO
