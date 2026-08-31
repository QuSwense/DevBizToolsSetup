/*
    Table: IndexingJsonFileElementMappings
    Description: Maps JSON file elements to their unique element references.
    Supports both request and response files.
*/
CREATE TABLE [dbo].[IndexingJsonFileElementMappings]
(
    -- Surrogate primary key. (The original composite key included the nullable
    -- RequestFileId/ResponseFileId columns, which is not permitted for a PK;
    -- uniqueness is enforced by the filtered unique indexes below.)
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    -- Foreign Key target for ServiceRequestFiles (NULL if FileSourceType = 'S')
    [RequestFileId] INT NULL,
    -- Foreign Key target for ServiceResponseFiles (NULL if FileSourceType = 'R')
    [ResponseFileId] INT NULL,
    -- Foreign Key referencing the unique entry in JsonFileElements.
    [ElementId] BIGINT NOT NULL,

    CONSTRAINT [PK_IndexingJsonFileElementMappings] 
        PRIMARY KEY CLUSTERED ([Id] ASC) 
        WITH (DATA_COMPRESSION = PAGE),
    CONSTRAINT CK_IndexingJsonFileElementMappings_OneParent
        CHECK (
            ([RequestFileId] IS NOT NULL AND [ResponseFileId] IS NULL)
            OR ([RequestFileId] IS NULL AND [ResponseFileId] IS NOT NULL)
        ),

    CONSTRAINT [FK_IndexingJsonFileElementMappings_IndexingJsonFileElements] 
        FOREIGN KEY ([ElementId]) REFERENCES [dbo].[IndexingJsonFileElements]([ElementId]) ON DELETE CASCADE
);
GO

-- Enforce a single mapping per (element, request file).
CREATE UNIQUE NONCLUSTERED INDEX [UX_IndexingJsonFileElementMappings_RequestFileId]
ON [dbo].[IndexingJsonFileElementMappings] ([ElementId] ASC, [RequestFileId] ASC)
WHERE [RequestFileId] IS NOT NULL
WITH (DATA_COMPRESSION = PAGE);
GO

-- Enforce a single mapping per (element, response file).
CREATE UNIQUE NONCLUSTERED INDEX [UX_IndexingJsonFileElementMappings_ResponseFileId]
ON [dbo].[IndexingJsonFileElementMappings] ([ElementId] ASC, [ResponseFileId] ASC)
WHERE [ResponseFileId] IS NOT NULL
WITH (DATA_COMPRESSION = PAGE);
GO

-- Reverse lookup index supporting search queries finding all file IDs containing a specific ElementId.
CREATE NONCLUSTERED INDEX [IX_IndexingJsonFileElementMappings_ElementId] 
ON [dbo].[IndexingJsonFileElementMappings] ([ElementId] ASC, [RequestFileId] ASC, [ResponseFileId] ASC) 
WITH (DATA_COMPRESSION = PAGE);
GO

-- Index for request file lookups
CREATE NONCLUSTERED INDEX [IX_IndexingJsonFileElementMappings_RequestFileId] 
ON [dbo].[IndexingJsonFileElementMappings] ([RequestFileId] ASC) 
WHERE [RequestFileId] IS NOT NULL
WITH (DATA_COMPRESSION = PAGE);
GO

-- Index for response file lookups
CREATE NONCLUSTERED INDEX [IX_IndexingJsonFileElementMappings_ResponseFileId] 
ON [dbo].[IndexingJsonFileElementMappings] ([ResponseFileId] ASC) 
WHERE [ResponseFileId] IS NOT NULL
WITH (DATA_COMPRESSION = PAGE);
GO