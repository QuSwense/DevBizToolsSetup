/*
    Table-valued parameter type used by usp_SaveServiceRequestFile.

    One row = one binary embedding link that belongs to the request file
    being saved. BinaryEmbeddingsStoreId must already exist (content-addressable
    store is handled by a separate procedure / caller).
*/
IF NOT EXISTS (SELECT 1 FROM sys.types WHERE name = 'ServiceRequestFileEmbeddingLinkInput' AND is_table_type = 1)
BEGIN
    CREATE TYPE [dbo].[ServiceRequestFileEmbeddingLinkInput] AS TABLE
    (
        [ElementName]               NVARCHAR(400)   NOT NULL,
        [XmlPath]                   NVARCHAR(400)   NOT NULL,
        [BinaryEmbeddingsStoreId]   INT             NOT NULL,
        [Name]                      NVARCHAR(250)   NOT NULL,
        [AdditionalDetails]         NVARCHAR(MAX)   NULL
    );
END
GO
