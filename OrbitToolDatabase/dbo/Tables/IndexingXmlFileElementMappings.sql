/*
    Table: IndexingXmlFileElementMappings
    Description: Maps XML file elements to their unique element references.
    Supports both request and response files.
*/
CREATE TABLE [dbo].[IndexingXmlFileElementMappings]
(
    -- Primary key.
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    -- Foreign Key target for ServiceRequestFiles (NULL if FileSourceType = 'S')
    [RequestFileId] INT NULL,
    -- Foreign Key target for ServiceResponseFiles (NULL if FileSourceType = 'R')
    [ResponseFileId] INT NULL,
    -- Foreign Key referencing the unique entry in IndexingXmlFileElementSearch.
    [IndexingXmlFileElementSearchId] BIGINT NOT NULL,

    CONSTRAINT [PK_IndexingXmlFileElementMappings] 
        PRIMARY KEY CLUSTERED ([Id] ASC) 
        WITH (DATA_COMPRESSION = PAGE),

    CONSTRAINT [FK_IndexingXmlFileElementMappings_IndexingXmlFileElementSearch] 
        FOREIGN KEY ([IndexingXmlFileElementSearchId]) REFERENCES [dbo].[IndexingXmlFileElementSearch]([Id]) ON DELETE CASCADE,

    CONSTRAINT [FK_IndexingXmlFileElementMappings_ServiceRequestFiles] 
        FOREIGN KEY ([RequestFileId]) REFERENCES [dbo].[ServiceRequestFiles]([Id]),
    CONSTRAINT [FK_IndexingXmlFileElementMappings_ServiceResponseFiles] 
        FOREIGN KEY ([ResponseFileId]) REFERENCES [dbo].[ServiceResponseFiles]([Id])
);
GO
