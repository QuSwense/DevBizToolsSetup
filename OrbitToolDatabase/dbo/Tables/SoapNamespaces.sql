CREATE TABLE [dbo].[SoapNamespaces] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [ServiceOperationSchemaId] INT NOT NULL,
    [Prefix] NVARCHAR(50) NOT NULL,
    [NamespaceUri] NVARCHAR(500) NOT NULL,
    [CreatedAt] DATETIME NOT NULL
        CONSTRAINT [DF_SoapNamespaces_CreatedAt] DEFAULT GETDATE(),

    -- Primary Key
    CONSTRAINT [PK_SoapNamespaces] PRIMARY KEY CLUSTERED ([Id] ASC),

    -- Foreign Keys
    CONSTRAINT [FK_SoapNamespaces_ServiceOperationSchemas_ServiceOperationSchemaId]
        FOREIGN KEY ([ServiceOperationSchemaId]) REFERENCES [dbo].[ServiceOperationSchemas]([Id]) ON DELETE CASCADE
)
GO

CREATE NONCLUSTERED INDEX [IX_SoapNamespaces_ServiceOperationSchemaId]
    ON [dbo].[SoapNamespaces]([ServiceOperationSchemaId] ASC)
GO

CREATE NONCLUSTERED INDEX [IX_SoapNamespaces_Prefix]
    ON [dbo].[SoapNamespaces]([Prefix] ASC)
GO

CREATE NONCLUSTERED INDEX [IX_SoapNamespaces_NamespaceUri]
    ON [dbo].[SoapNamespaces]([NamespaceUri] ASC)
