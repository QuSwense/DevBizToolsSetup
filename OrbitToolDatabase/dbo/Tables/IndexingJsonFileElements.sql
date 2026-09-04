/*
    Table: IndexingJsonFileElements
    Description: Stores unique JSON element key-value combinations for indexing.
    Similar to XML elements but optimized for JSON path structures.
*/
CREATE TABLE [dbo].[IndexingJsonFileElements]
(
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    -- Primary Key, auto-incrementing identity integer.
    [ElementName] NVARCHAR(400) NOT NULL,
    -- JSON Path key path, using JSONPath in C#
    [JsonPath] NVARCHAR(400) NOT NULL,
    -- JSON value type: 'String', 'Number', 'Boolean', 'Null', 'Array', 'Object'
    [ValueType] NVARCHAR(20) NOT NULL DEFAULT 'String',
    [CreatedAt] DATETIME NOT NULL DEFAULT GETDATE(),
    [UpdatedAt] DATETIME NULL,

    CONSTRAINT [PK_IndexingJsonFileElements] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (DATA_COMPRESSION = PAGE),
    CONSTRAINT [CK_IndexingJsonFileElements_ValueType] CHECK ([ValueType] IN ('String', 'Number', 'Boolean', 'Null', 'Array', 'Object'))
);
GO

-- Index supporting wildcard and exact-value searches across JSON values.
CREATE NONCLUSTERED INDEX [IX_IndexingJsonFileElements_Value_KeyPath] 
ON [dbo].[IndexingJsonFileElements] ([ElementName] ASC, [JsonPath] ASC) 
INCLUDE ([Id]);
GO
