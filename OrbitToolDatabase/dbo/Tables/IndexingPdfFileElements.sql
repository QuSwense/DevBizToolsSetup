/*
    Table: IndexingPdfFileElements
    Description: Stores unique PDF element key-value combinations for indexing.
    Similar to JSON elements but optimized for PDF path structures.
*/
CREATE TABLE [dbo].[IndexingPdfFileElements]
(
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    -- Primary Key, auto-incrementing identity integer.
    [ElementName] NVARCHAR(400) NOT NULL,
    -- Type of the PDF element, e.g., 'Text', 'Image', 'Table'
    [ElementType] NVARCHAR(100) NOT NULL,
    [PageNumber] INT NOT NULL,
    [BoundingRectangle] NVARCHAR(400) NOT NULL,
    -- PDF value type: 'String', 'Number', 'Boolean', 'Array', 'Object'
    [ValueType] NVARCHAR(20) NOT NULL DEFAULT 'String',
    [CreatedAt] DATETIME NOT NULL DEFAULT GETDATE(),
    [UpdatedAt] DATETIME NULL,

    CONSTRAINT [PK_IndexingPdfFileElements] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (DATA_COMPRESSION = PAGE),
    CONSTRAINT [CK_IndexingPdfFileElements_ValueType] CHECK ([ValueType] IN ('String', 'Number', 'Boolean', 'Null', 'Array', 'Object'))
);
GO

-- Index supporting wildcard and exact-value searches across PDF values.
CREATE NONCLUSTERED INDEX [IX_IndexingPdfFileElements_Value_KeyPath] 
ON [dbo].[IndexingPdfFileElements] ([ElementName] ASC, [ElementType] ASC) 
INCLUDE ([Id]);
GO
