/*
    Table: IndexingJsonFileElements
    Description: Stores unique JSON element key-value combinations for indexing.
    Similar to XML elements but optimized for JSON path structures.
*/
CREATE TABLE [dbo].[IndexingJsonFileElements]
(
    -- Primary Key, auto-incrementing identity integer.
    [ElementId] BIGINT IDENTITY(1,1) NOT NULL,
    -- JSON Path key path (e.g., '$.Orders.Order.Address.City').
    [JsonPathKeyPath] VARCHAR(400) NOT NULL,
    -- String representation of the scalar value (e.g., 'Pune').
    [ElementValue] NVARCHAR(450) NOT NULL,
    -- JSON value type: 'String', 'Number', 'Boolean', 'Null', 'Array', 'Object'
    [ValueType] VARCHAR(20) NOT NULL DEFAULT 'String',
    -- Binary SHA-256 hash calculated over (NormalizedKeyPath + '|' + ElementValue + '|' + ValueType) for fast uniqueness matching.
    [ValueHash] BINARY(32) NOT NULL,

    CONSTRAINT [PK_IndexingJsonFileElements] PRIMARY KEY CLUSTERED ([ElementId] ASC) WITH (DATA_COMPRESSION = PAGE)
);
GO

-- Unique index enforcing global single-instance storage of JSON element key-value combinations.
CREATE UNIQUE NONCLUSTERED INDEX [UX_IndexingJsonFileElements_ValueHash] 
ON [dbo].[IndexingJsonFileElements] ([ValueHash]) 
INCLUDE ([ElementId]);
GO

-- Index supporting wildcard and exact-value searches across JSON values.
CREATE NONCLUSTERED INDEX [IX_IndexingJsonFileElements_Value_KeyPath] 
ON [dbo].[IndexingJsonFileElements] ([ElementValue] ASC, [JsonPathKeyPath] ASC) 
INCLUDE ([ElementId]);
GO

-- Index supporting exact key-path searches.
CREATE NONCLUSTERED INDEX [IX_IndexingJsonFileElements_KeyPath_Value] 
ON [dbo].[IndexingJsonFileElements] ([JsonPathKeyPath] ASC, [ElementValue] ASC) 
INCLUDE ([ElementId]);
GO

-- Index supporting value type filtering
CREATE NONCLUSTERED INDEX [IX_IndexingJsonFileElements_ValueType] 
ON [dbo].[IndexingJsonFileElements] ([ValueType] ASC) 
INCLUDE ([ElementValue], [JsonPathKeyPath]);
GO