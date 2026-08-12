-- ============================================
-- 1. SOAP APPLICATIONS
-- ============================================
-- Stores SOAP application/service definitions
-- ============================================

CREATE TABLE [dbo].[SoapApps] (
    [Id]              INT IDENTITY(1,1) NOT NULL,
    [Guid]            UNIQUEIDENTIFIER NOT NULL 
                      CONSTRAINT [DF_SoapApps_Guid] DEFAULT (NEWSEQUENTIALID()),
    [Name]            NVARCHAR(100) NOT NULL,
    [BaseUrl]         NVARCHAR(500) NOT NULL,           -- Base URL of the SOAP service
    [WsdlPath]        NVARCHAR(500) NOT NULL DEFAULT '', -- Path/relative URL to WSDL
    [Status]          NVARCHAR(20) NOT NULL 
                      CONSTRAINT [DF_SoapApps_Status] DEFAULT ('Enabled')
                      CONSTRAINT [CK_SoapApps_Status] 
                      CHECK ([Status] IN ('Enabled', 'Disabled', 'Archived')),
    [AuthConfigId]    INT NULL, -- NULL means no authentication required
    [LogDbAuthConfigId] INT NULL, -- Auth config for logging database
    
    -- Audit
    [CreatedBy]       NVARCHAR(100) NOT NULL,
    [UpdatedBy]       NVARCHAR(100) NULL,
    [CreatedAt]       DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    [UpdatedAt]       DATETIME2 NULL,
    
    -- Soft delete
    [IsActive]        BIT NOT NULL DEFAULT (1),
    
    -- Concurrency
    [RowVersion]      ROWVERSION NOT NULL,
    
    CONSTRAINT [PK_SoapApps] 
        PRIMARY KEY NONCLUSTERED ([Guid]),
    CONSTRAINT [UX_SoapApps_Id] 
        UNIQUE CLUSTERED ([Id]),
    CONSTRAINT [UQ_SoapApps_Name] 
        UNIQUE ([Name]),
    CONSTRAINT [UQ_SoapApps_BaseUrl_WsdlPath] 
        UNIQUE ([BaseUrl], [WsdlPath]),
    CONSTRAINT [FK_SoapApps_AuthConfig] 
        FOREIGN KEY ([AuthConfigId]) 
        REFERENCES [dbo].[AuthConfigs]([Id]) 
        ON DELETE SET NULL,
    CONSTRAINT [FK_SoapApps_LogDbAuthConfig] 
        FOREIGN KEY ([LogDbAuthConfigId]) 
        REFERENCES [dbo].[AuthConfigs]([Id]) 
        ON DELETE SET NULL
);

GO

-- For SoapApps table
CREATE NONCLUSTERED INDEX [IX_SoapApps_AuthConfigId] 
    ON [dbo].[SoapApps] ([AuthConfigId]);
    
CREATE NONCLUSTERED INDEX [IX_SoapApps_LogDbAuthConfigId] 
    ON [dbo].[SoapApps] ([LogDbAuthConfigId]);
    
CREATE NONCLUSTERED INDEX [IX_SoapApps_Status] 
    ON [dbo].[SoapApps] ([Status]);
    
CREATE NONCLUSTERED INDEX [IX_SoapApps_IsActive] 
    ON [dbo].[SoapApps] ([IsActive]);

GO