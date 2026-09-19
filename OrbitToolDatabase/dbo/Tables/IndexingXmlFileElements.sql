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
    -- XML value type: maps to c# type
    [DataType] NVARCHAR(200) NOT NULL,
    [CreatedAt] DATETIME2(3) NOT NULL DEFAULT GETDATE(),

    CONSTRAINT [PK_IndexingXmlFileElements] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (DATA_COMPRESSION = PAGE),
    CONSTRAINT [UQ_IndexingXmlFileElements_ElementName_XmlPath] UNIQUE ([ElementName] ASC, [XmlPath] ASC)
);
GO

-- Index supporting wildcard and exact-value searches across XML values.
CREATE NONCLUSTERED INDEX [IX_IndexingXmlFileElements_ElementName_XmlPath] 
ON [dbo].[IndexingXmlFileElements] ([ElementName] ASC, [XmlPath] ASC) 
INCLUDE ([Id]);
GO
