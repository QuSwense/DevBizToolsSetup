CREATE TABLE [dbo].[ServiceOperationSchemas] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [DefinitionSyncId] INT NOT NULL,
    [OperationId] INT NULL,
    [TargetNamespace] NVARCHAR(500) NULL,
    [SchemaContent] NVARCHAR(MAX) NOT NULL,
    [CreatedAt] DATETIME NOT NULL
        CONSTRAINT [DF_ServiceOperationSchemas_CreatedAt] DEFAULT GETDATE(),

    -- Primary Key
    CONSTRAINT [PK_ServiceOperationSchemas] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT CK_ServiceOperationSchemas_TargetNamespace
        CHECK ([TargetNamespace] IS NULL OR LEFT([TargetNamespace], 7) = 'http://' OR LEFT([TargetNamespace], 8) = 'https://'),
    -- Check schema content is xml
    CONSTRAINT CK_ServiceOperationSchemas_SchemaContent
        CHECK (TRY_CAST([SchemaContent] AS XML) IS NOT NULL),

    -- Foreign Keys
    CONSTRAINT [FK_ServiceOperationSchemas_ServiceDefinitionSync_DefinitionSyncId]
        FOREIGN KEY ([DefinitionSyncId])
        REFERENCES [dbo].[ServiceDefinitionSyncs]([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_ServiceOperationSchemas_ServiceOperations_OperationId]
        FOREIGN KEY ([OperationId])
        REFERENCES [dbo].[ServiceOperations]([Id])
)
GO

CREATE NONCLUSTERED INDEX [IX_ServiceOperationSchemas_DefinitionSyncId]
    ON [dbo].[ServiceOperationSchemas]([DefinitionSyncId] ASC)
GO

CREATE NONCLUSTERED INDEX [IX_ServiceOperationSchemas_OperationId]
    ON [dbo].[ServiceOperationSchemas]([OperationId] ASC)
