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
    -- JSON value types, C# types
    [DataType] NVARCHAR(200) NOT NULL,
    [CreatedAt] DATETIME2(3) NOT NULL DEFAULT GETDATE(),

    CONSTRAINT [PK_IndexingJsonFileElements] PRIMARY KEY CLUSTERED ([Id] ASC) WITH (DATA_COMPRESSION = PAGE),
    CONSTRAINT [UQ_IndexingJsonFileElements_ElementName_JsonPath] UNIQUE ([ElementName] ASC, [JsonPath] ASC),
);
GO

-- Index supporting wildcard and exact-value searches across JSON values.
CREATE NONCLUSTERED INDEX [IX_IndexingJsonFileElements_ElementName_JsonPath] 
ON [dbo].[IndexingJsonFileElements] ([ElementName] ASC, [JsonPath] ASC) 
INCLUDE ([Id]);
GO
