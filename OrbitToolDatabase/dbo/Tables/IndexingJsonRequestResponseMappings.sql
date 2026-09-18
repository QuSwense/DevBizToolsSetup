/*
    Table: IndexingJsonRequestResponseMappings
    Description: Maps JSON file elements to their unique element references.
    Supports both request and response files.
*/
CREATE TABLE [dbo].[IndexingJsonRequestResponseMappings]
(
    -- Primary key.
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    [RequestFileId] BIGINT NULL,
    [ResponseFileId] BIGINT NULL,
    -- Foreign Key referencing the unique entry in IndexingJsonFileElementSearch.
    [IndexingJsonFileElementValueId] BIGINT NOT NULL,

    CONSTRAINT [PK_IndexingJsonRequestResponseMappings] PRIMARY KEY CLUSTERED ([Id] ASC),

    CONSTRAINT [FK_IndexingJsonRequestResponseMappings_IndexingJsonFileElementValues] 
        FOREIGN KEY ([IndexingJsonFileElementValueId]) REFERENCES [dbo].[IndexingJsonFileElementValues]([Id]),

    -- NO ACTION: ServiceRequestFiles already reaches this table through ServiceResponseFiles
    -- (which cascades from ServiceRequestFiles), so CASCADE here would be a second
    -- cascade path to the same table (Msg 1785).
    CONSTRAINT [FK_IndexingJsonRequestResponseMappings_ServiceRequestFiles] 
        FOREIGN KEY ([RequestFileId]) REFERENCES [dbo].[ServiceRequestFiles]([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_IndexingJsonRequestResponseMappings_ServiceResponseFiles] 
        FOREIGN KEY ([ResponseFileId]) REFERENCES [dbo].[ServiceResponseFiles]([Id]) ON DELETE NO ACTION
);
GO

CREATE NONCLUSTERED INDEX [IX_IndexingJsonRequestResponseMappings_RequestFileId]
    ON [dbo].[IndexingJsonRequestResponseMappings]([RequestFileId] ASC)
GO

CREATE NONCLUSTERED INDEX [IX_IndexingJsonRequestResponseMappings_ResponseFileId]
    ON [dbo].[IndexingJsonRequestResponseMappings]([ResponseFileId] ASC)
GO

CREATE NONCLUSTERED INDEX [IX_IndexingJsonRequestResponseMappings_ValueId]
    ON [dbo].[IndexingJsonRequestResponseMappings]([IndexingJsonFileElementValueId] ASC)
GO
