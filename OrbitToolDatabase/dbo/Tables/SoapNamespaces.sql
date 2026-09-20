/*
    Table: SoapNamespaces
    Description: Stores SOAP namespace definitions associated with service operation schemas.
*/
CREATE TABLE [dbo].[SoapNamespaces] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Public Identifier for UI/Secure Operations (GUID)
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_SoapNamespaces_PublicId DEFAULT NEWID(),
    -- Foreign Key to ServiceOperationSchemas table
    [ServiceOperationSchemaId] INT NOT NULL,
    -- JSON file of array of ns name and the uri
    [DetailContent] NVARCHAR(MAX) NOT NULL,
    -- Record version for optimistic concurrency control, formatted as 'YY.QQ.NN', e.g., '24.10.01'
    [RecordVersion] VARCHAR(50) NOT NULL
        CONSTRAINT DF_SoapNamespaces_RecordVersion DEFAULT ([dbo].[fn_CalculateVersion](NULL)),
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME2(3) NOT NULL CONSTRAINT [DF_SoapNamespaces_CreatedAt] DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NULL,

    -- Primary Key
    CONSTRAINT [PK_SoapNamespaces] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ_SoapNamespaces_PublicId] UNIQUE ([PublicId] ASC),
    CONSTRAINT [UQ_SoapNamespaces_Schema_RecordVersion] UNIQUE ([ServiceOperationSchemaId] ASC, [RecordVersion] ASC),
    -- Removed constraints related to compression and content hash as the content is now JSON text
    CONSTRAINT CK_SoapNamespaces_RecordVersionFormat
        CHECK ([RecordVersion] LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9]'),

    -- Foreign Keys
    CONSTRAINT [FK_SoapNamespaces_ServiceOperationSchemas_ServiceOperationSchemaId]
        FOREIGN KEY ([ServiceOperationSchemaId]) REFERENCES [dbo].[ServiceOperationSchemas]([Id]),
    CONSTRAINT FK_SoapNamespaces_CreatedBy_Users
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId])
);
GO

CREATE NONCLUSTERED INDEX [IX_SoapNamespaces_ServiceOperationSchemaId]
    ON [dbo].[SoapNamespaces]([ServiceOperationSchemaId] ASC)
GO
