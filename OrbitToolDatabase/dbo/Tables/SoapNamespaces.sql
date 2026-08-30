/*
    Table: SoapNamespaces
    Description: Stores SOAP namespace definitions associated with service operation schemas.
*/
CREATE TABLE [dbo].[SoapNamespaces] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Foreign Key to ServiceOperationSchemas table
    [ServiceOperationSchemaId] INT NOT NULL,
    -- Namespace prefix, e.g., 'ns1', 'soapenv', etc. extracted from the XSD extracted from SOAP WSDL
    [Prefix] NVARCHAR(50) NOT NULL,
    -- Namespace URI, e.g., 'http://example.com/namespace' extracted from the XSD extracted from SOAP WSDL
    [NamespaceUri] NVARCHAR(500) NOT NULL,
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME NOT NULL CONSTRAINT [DF_SoapNamespaces_CreatedAt] DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

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
