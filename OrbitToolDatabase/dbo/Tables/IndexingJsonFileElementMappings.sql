/*
    Table: IndexingJsonFileElementMappings
    Description: Maps JSON file elements to their unique element references.
    Supports both request and response files.
*/
CREATE TABLE [dbo].[IndexingJsonFileElementMappings]
(
    -- Primary key.
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    -- Foreign Key target for ServiceRequestFiles (NULL if FileSourceType = 'S')
    [RequestFileId] INT NULL,
    -- Foreign Key target for ServiceResponseFiles (NULL if FileSourceType = 'R')
    [ResponseFileId] INT NULL,
    -- Foreign Key referencing the unique entry in IndexingJsonFileElementSearch.
    [IndexingJsonFileElementSearchId] BIGINT NOT NULL,

    CONSTRAINT [PK_IndexingJsonFileElementMappings] 
        PRIMARY KEY CLUSTERED ([Id] ASC) 
        WITH (DATA_COMPRESSION = PAGE),

    CONSTRAINT [FK_IndexingJsonFileElementMappings_IndexingJsonFileElementSearch] 
        FOREIGN KEY ([IndexingJsonFileElementSearchId]) REFERENCES [dbo].[IndexingJsonFileElementSearch]([Id]) ON DELETE CASCADE,

    CONSTRAINT [FK_IndexingJsonFileElementMappings_ServiceRequestFiles] 
        FOREIGN KEY ([RequestFileId]) REFERENCES [dbo].[ServiceRequestFiles]([Id]),
    CONSTRAINT [FK_IndexingJsonFileElementMappings_ServiceResponseFiles] 
        FOREIGN KEY ([ResponseFileId]) REFERENCES [dbo].[ServiceResponseFiles]([Id])
);
GO
