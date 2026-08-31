CREATE TABLE [dbo].[IndexingXmlFileElementMappings]
(
    -- Surrogate primary key. (The original composite key included the nullable
    -- RequestFileId/ResponseFileId columns, which is not permitted for a PK;
    -- uniqueness is enforced by the filtered unique indexes below.)
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    -- Foreign Key target for ServiceRequestFiles (NULL if FileSourceType = 'S')
    [RequestFileId] INT NULL,
    -- Foreign Key target for ServiceResponseFiles (NULL if FileSourceType = 'R')
    [ResponseFileId] INT NULL,
    -- Foreign Key referencing the unique entry in FileElements.
    [ElementId] BIGINT NOT NULL,

    CONSTRAINT [PK_IndexingXmlFileElementMappings] 
        PRIMARY KEY CLUSTERED ([Id] ASC) 
        WITH (DATA_COMPRESSION = PAGE),
    CONSTRAINT CK_IndexingFileElementMappings_OneParent
        CHECK (
            ([RequestFileId] IS NOT NULL AND [ResponseFileId] IS NULL)
            OR ([RequestFileId] IS NULL AND [ResponseFileId] IS NOT NULL)
        ),

    CONSTRAINT [FK_IndexingXmlFileElementMappings_IndexingXmlFileElements] FOREIGN KEY ([ElementId]) REFERENCES [dbo].[IndexingXmlFileElements]([ElementId]) ON DELETE CASCADE
);
GO

-- Enforce a single mapping per (element, request file).
CREATE UNIQUE NONCLUSTERED INDEX [UX_IndexingXmlFileElementMappings_RequestFileId]
ON [dbo].[IndexingXmlFileElementMappings] ([ElementId] ASC, [RequestFileId] ASC)
WHERE [RequestFileId] IS NOT NULL;
GO

-- Enforce a single mapping per (element, response file).
CREATE UNIQUE NONCLUSTERED INDEX [UX_IndexingXmlFileElementMappings_ResponseFileId]
ON [dbo].[IndexingXmlFileElementMappings] ([ElementId] ASC, [ResponseFileId] ASC)
WHERE [ResponseFileId] IS NOT NULL;
GO

-- Reverse lookup index supporting search queries finding all file IDs containing a specific ElementId.
CREATE NONCLUSTERED INDEX [IX_IndexingXmlFileElementMappings_ElementId] 
ON [dbo].[IndexingXmlFileElementMappings] ([ElementId] ASC, [RequestFileId] ASC, [ResponseFileId] ASC) 
WITH (DATA_COMPRESSION = PAGE);
GO