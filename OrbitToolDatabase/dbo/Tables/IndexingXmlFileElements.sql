CREATE TABLE [dbo].[IndexingXmlFileElements]
(
  -- Primary Key, auto-incrementing identity integer.
    [ElementId] BIGINT IDENTITY(1,1) NOT NULL,
    -- XPath key path (e.g., '/Orders/Order/Address/City').
    [XPathKeyPath] VARCHAR(400) NOT NULL,
    -- String representation of the scalar value (e.g., 'Pune').
    [ElementValue] NVARCHAR(450) NOT NULL,
    -- Binary SHA-256 hash calculated over (NormalizedKeyPath + '|' + ElementValue) for fast uniqueness matching.
    [ValueHash] BINARY(32) NOT NULL,

    CONSTRAINT [PK_IndexingXmlFileElements] PRIMARY KEY CLUSTERED ([ElementId] ASC) WITH (DATA_COMPRESSION = PAGE)
);
GO

-- Unique index enforcing global single-instance storage of element key-value combinations.
CREATE UNIQUE NONCLUSTERED INDEX [UX_IndexingXmlFileElements_ValueHash] 
ON [dbo].[IndexingXmlFileElements] ([ValueHash]) 
INCLUDE ([ElementId]);
GO

-- Index supporting wildcard and exact-value searches across element values.
CREATE NONCLUSTERED INDEX [IX_IndexingXmlFileElements_Value_KeyPath] 
ON [dbo].[IndexingXmlFileElements] ([ElementValue] ASC, [XPathKeyPath] ASC) 
INCLUDE ([ElementId]);
GO

-- Index supporting exact key-path searches.
CREATE NONCLUSTERED INDEX [IX_IndexingXmlFileElements_KeyPath_Value] 
ON [dbo].[IndexingXmlFileElements] ([XPathKeyPath] ASC, [ElementValue] ASC) 
INCLUDE ([ElementId]);
GO