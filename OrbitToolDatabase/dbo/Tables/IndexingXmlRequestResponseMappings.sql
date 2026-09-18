/*
    Table: IndexingXmlRequestResponseMappings
    Description: Maps XML file elements to their unique element references.
    Supports both request and response files.
*/
CREATE TABLE [dbo].[IndexingXmlRequestResponseMappings]
(
    -- Primary key.
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    -- Foreign Key target for ServiceRequestFiles
    [RequestFileId] INT NULL,
    -- Foreign Key target for ServiceResponseFiles
    [ResponseFileId] INT NULL,
    -- Foreign Key referencing the unique entry in IndexingXmlFileElementSearch.
    [IndexingXmlFileElementValueId] BIGINT NOT NULL,

    CONSTRAINT [PK_IndexingXmlRequestResponseMappings] 
        PRIMARY KEY CLUSTERED ([Id] ASC) 
        WITH (DATA_COMPRESSION = PAGE),

    CONSTRAINT [FK_IndexingXmlRequestResponseMappings_IndexingXmlFileElementValues] 
        FOREIGN KEY ([IndexingXmlFileElementValueId]) REFERENCES [dbo].[IndexingXmlFileElementValues]([Id]),

    -- NO ACTION: ServiceRequestFiles already reaches this table through ServiceResponseFiles
    -- (which cascades from ServiceRequestFiles), so CASCADE here would be a second
    -- cascade path to the same table (Msg 1785).
    CONSTRAINT [FK_IndexingXmlRequestResponseMappings_ServiceRequestFiles] 
        FOREIGN KEY ([RequestFileId]) REFERENCES [dbo].[ServiceRequestFiles]([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_IndexingXmlRequestResponseMappings_ServiceResponseFiles] 
        FOREIGN KEY ([ResponseFileId]) REFERENCES [dbo].[ServiceResponseFiles]([Id]) ON DELETE NO ACTION
);
GO

CREATE NONCLUSTERED INDEX [IX_IndexingXmlRequestResponseMappings_RequestFileId]
    ON [dbo].[IndexingXmlRequestResponseMappings]([RequestFileId] ASC)
GO

CREATE NONCLUSTERED INDEX [IX_IndexingXmlRequestResponseMappings_ResponseFileId]
    ON [dbo].[IndexingXmlRequestResponseMappings]([ResponseFileId] ASC)
GO

CREATE NONCLUSTERED INDEX [IX_IndexingXmlRequestResponseMappings_ValueId]
    ON [dbo].[IndexingXmlRequestResponseMappings]([IndexingXmlFileElementValueId] ASC)
GO
