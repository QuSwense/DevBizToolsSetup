-- ============================================
-- 2. SOAP OPERATIONS
-- ============================================
-- Stores SOAP operations/endpoints for each application
-- ============================================

CREATE TABLE [dbo].[SoapOperations] (
    [Id]              INT IDENTITY(1,1) NOT NULL,
    [Guid]            UNIQUEIDENTIFIER NOT NULL 
                      CONSTRAINT [DF_SoapOperations_Guid] DEFAULT (NEWSEQUENTIALID()),
    [SoapAppId]       INT NOT NULL,           -- Reference to parent SOAP app
    [Name]            NVARCHAR(100) NOT NULL, -- Operation/method name
    [Action]          NVARCHAR(200) NULL,     -- SOAP action header
    [RelativePath]    NVARCHAR(500) NULL,     -- Relative URL path for this operation
    [Description]     NVARCHAR(500) NULL,
    [Status]          NVARCHAR(20) NOT NULL 
                      CONSTRAINT [DF_SoapOperations_Status] DEFAULT ('Enabled')
                      CONSTRAINT [CK_SoapOperations_Status] 
                      CHECK ([Status] IN ('Enabled', 'Disabled', 'Archived')),
    
    -- Audit
    [CreatedBy]       NVARCHAR(100) NOT NULL,
    [UpdatedBy]       NVARCHAR(100) NULL,
    [CreatedAt]       DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    [UpdatedAt]       DATETIME2 NULL,
    
    -- Soft delete
    [IsActive]        BIT NOT NULL DEFAULT (1),
    
    -- Concurrency
    [RowVersion]      ROWVERSION NOT NULL,
    
    CONSTRAINT [PK_SoapOperations] 
        PRIMARY KEY NONCLUSTERED ([Guid]),
    CONSTRAINT [UX_SoapOperations_Id] 
        UNIQUE CLUSTERED ([Id]),
    CONSTRAINT [UQ_SoapOperations_AppName] 
        UNIQUE ([SoapAppId], [Name]),
    CONSTRAINT [FK_SoapOperations_SoapApp] 
        FOREIGN KEY ([SoapAppId]) 
        REFERENCES [dbo].[SoapApps]([Id]) 
        ON DELETE CASCADE
);

GO

-- For SoapOperations table
CREATE NONCLUSTERED INDEX [IX_SoapOperations_SoapAppId] 
    ON [dbo].[SoapOperations] ([SoapAppId]);
    
CREATE NONCLUSTERED INDEX [IX_SoapOperations_Status] 
    ON [dbo].[SoapOperations] ([Status]);
    
CREATE NONCLUSTERED INDEX [IX_SoapOperations_IsActive] 
    ON [dbo].[SoapOperations] ([IsActive]);

GO