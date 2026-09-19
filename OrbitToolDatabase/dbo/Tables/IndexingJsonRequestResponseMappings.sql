/*
    Table: IndexingJsonRequestResponseMappings
    Description: Maps JSON file elements to their unique element references.
    Supports both request and response files.
*/
CREATE TABLE [dbo].[IndexingJsonRequestResponseMappings]
(
    -- Primary key.
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    [ServiceRequestFileId] BIGINT NULL,
    [ServiceResponseFileId] BIGINT NULL,
    -- Foreign Key referencing the unique entry in IndexingJsonFileElementSearch.
    [IndexingJsonFileElementValueId] BIGINT NOT NULL,
    [CreatedAt] DATETIME2(3) NOT NULL DEFAULT GETDATE(),

    CONSTRAINT [PK_IndexingJsonRequestResponseMappings] PRIMARY KEY CLUSTERED ([Id] ASC),

    CONSTRAINT [FK_IndexingJsonRequestResponseMappings_IndexingJsonFileElementValues] 
        FOREIGN KEY ([IndexingJsonFileElementValueId]) REFERENCES [dbo].[IndexingJsonFileElementValues]([Id]),

    -- NO ACTION: ServiceRequestFiles already reaches this table through ServiceResponseFiles
    -- (which cascades from ServiceRequestFiles), so CASCADE here would be a second
    -- cascade path to the same table (Msg 1785).
    CONSTRAINT [FK_IndexingJsonRequestResponseMappings_ServiceRequestFiles] 
        FOREIGN KEY ([ServiceRequestFileId]) REFERENCES [dbo].[ServiceRequestFiles]([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_IndexingJsonRequestResponseMappings_ServiceResponseFiles] 
        FOREIGN KEY ([ServiceResponseFileId]) REFERENCES [dbo].[ServiceResponseFiles]([Id]) ON DELETE NO ACTION
);
GO

CREATE NONCLUSTERED INDEX [IX_IndexingJsonRequestResponseMappings_ServiceRequestFileId]
    ON [dbo].[IndexingJsonRequestResponseMappings]([ServiceRequestFileId] ASC)
GO

CREATE NONCLUSTERED INDEX [IX_IndexingJsonRequestResponseMappings_ServiceResponseFileId]
    ON [dbo].[IndexingJsonRequestResponseMappings]([ServiceResponseFileId] ASC)
GO

CREATE NONCLUSTERED INDEX [IX_IndexingJsonRequestResponseMappings_ValueId]
    ON [dbo].[IndexingJsonRequestResponseMappings]([IndexingJsonFileElementValueId] ASC)
GO
