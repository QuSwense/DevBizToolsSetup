/*
    Table: IndexingFileElementType
    Description: Identifies the source type of the file element mapping.
    This helps determine which file type the mapping belongs to.
*/
CREATE TABLE [dbo].[IndexingFileElementType]
(
    -- Primary Key
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Type code: 'XML' or 'JSON'
    [ElementType] VARCHAR(10) NOT NULL,
    -- Description
    [Description] NVARCHAR(200) NULL,

    CONSTRAINT [PK_IndexingFileElementType] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ_IndexingFileElementType_ElementType] UNIQUE ([ElementType] ASC)
);
GO