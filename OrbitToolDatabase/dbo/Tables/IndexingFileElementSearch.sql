/*
    Table: IndexingFileElementSearch
    Description: Unified search view for both XML and JSON elements.
    Denormalized for faster searching across both element types.
*/
CREATE TABLE [dbo].[IndexingFileElementSearch]
(
    -- Primary Key
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    
    -- Element reference
    [ElementId] BIGINT NOT NULL,
    [ElementType] VARCHAR(10) NOT NULL, -- 'XML' or 'JSON'
    
    -- Path and value
    [KeyPath] VARCHAR(400) NOT NULL,
    [ElementValue] NVARCHAR(450) NOT NULL,
    [ValueType] VARCHAR(20) NULL,
    
    -- File references
    [RequestFileId] INT NULL,
    [ResponseFileId] INT NULL,
    
    -- Search optimization
    [ValueHash] BINARY(32) NOT NULL,
    [CreatedAt] DATETIME NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT [PK_IndexingFileElementSearch] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ_IndexingFileElementSearch_ElementId_ElementType] 
        UNIQUE ([ElementId] ASC, [ElementType] ASC)
);
GO

-- The full-text catalog and index are created by Script.PostDeployment.sql (project
-- deploy) and OrbitTool_ResetAndRecreate.sql (sqlcmd reset), guarded by
-- SERVERPROPERTY('IsFullTextInstalled') because they require the Full-Text Search
-- component, which is not available on every SQL Server instance.

-- Indexes for search optimization
CREATE NONCLUSTERED INDEX [IX_IndexingFileElementSearch_ElementValue_KeyPath] 
ON [dbo].[IndexingFileElementSearch] ([ElementValue] ASC, [KeyPath] ASC) 
INCLUDE ([ElementId], [ElementType]);
GO

CREATE NONCLUSTERED INDEX [IX_IndexingFileElementSearch_KeyPath_ElementValue] 
ON [dbo].[IndexingFileElementSearch] ([KeyPath] ASC, [ElementValue] ASC) 
INCLUDE ([ElementId], [ElementType]);
GO

CREATE NONCLUSTERED INDEX [IX_IndexingFileElementSearch_RequestFileId] 
ON [dbo].[IndexingFileElementSearch] ([RequestFileId] ASC) 
WHERE [RequestFileId] IS NOT NULL;
GO

CREATE NONCLUSTERED INDEX [IX_IndexingFileElementSearch_ResponseFileId] 
ON [dbo].[IndexingFileElementSearch] ([ResponseFileId] ASC) 
WHERE [ResponseFileId] IS NOT NULL;
GO

CREATE NONCLUSTERED INDEX [IX_IndexingFileElementSearch_ElementType_Value] 
ON [dbo].[IndexingFileElementSearch] ([ElementType] ASC, [ElementValue] ASC) 
INCLUDE ([KeyPath]);
GO