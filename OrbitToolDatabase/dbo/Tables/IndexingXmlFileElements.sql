/*
    Table: IndexingXmlFileElements
    Description: Stores unique XML element key-value combinations for indexing.
    Similar to JSON elements but optimized for XML path structures.
*/
CREATE TABLE [dbo].[IndexingXmlFileElements]
(
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    -- Primary Key, auto-incrementing identity integer.
    [ElementName] NVARCHAR(400) NOT NULL,
    -- XML Path key path, using XPath in C#
    [XmlPath] NVARCHAR(400) NOT NULL,
    -- XML value type: 'String', 'Number', 'Boolean', 'Array', 'Object'
    [ValueType] NVARCHAR(20) NOT NULL DEFAULT 'String',
    [CreatedAt] DATETIME NOT NULL DEFAULT GETDATE(),
    [UpdatedAt] DATETIME NULL,

    CONSTRAINT [PK_IndexingXmlFileElements] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (DATA_COMPRESSION = PAGE),
    CONSTRAINT [CK_IndexingXmlFileElements_ValueType] CHECK ([ValueType] IN ('String', 'Number', 'Boolean', 'Null', 'Array', 'Object'))
);
GO

-- Index supporting wildcard and exact-value searches across XML values.
CREATE NONCLUSTERED INDEX [IX_IndexingXmlFileElements_Value_KeyPath] 
ON [dbo].[IndexingXmlFileElements] ([ElementName] ASC, [XmlPath] ASC) 
INCLUDE ([Id]);
GO
