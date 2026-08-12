-- ============================================
-- 2. AUTH CONFIGURATIONS (Base Table)
-- ============================================
-- Generic auth configuration shared across all types
-- ============================================
-- CredentialsJson format by AuthType:
-- Basic: {"Username":"string","Password":"string"}
-- NTLM:  {"Username":"string","Password":"string","Domain":"string","NtlmVersion":"string"}
-- SQL:   {"Server":"string","Port":"string","Database":"string","Username":"string","Password":"string","Encrypt":true/false,"TrustServerCertificate":true/false,"AuthScheme":"string","IntegratedSecurity":true/false,"ConnectionTimeout":"string","CommandTimeout":"string","Pooling":true/false,"MinPoolSize":"string","MaxPoolSize":"string","ApplicationName":"string"}
-- Windows: {"AuthType":"string","Impersonate":true/false,"ImpersonationDomain":"string","ImpersonationUsername":"string","ImpersonationPassword":"string","RunAsAccount":"string","UseDefaultCredentials":true/false,"TokenImpersonationLevel":"string"}
-- ============================================

CREATE TABLE [dbo].[AuthConfigs] (
    [Id]              INT IDENTITY(1,1) NOT NULL,
    [Guid]            UNIQUEIDENTIFIER NOT NULL DEFAULT (NEWSEQUENTIALID()),
    [Name]            NVARCHAR(50) NOT NULL,
    [AuthType]        NVARCHAR(20) NOT NULL,
    [Description]     NVARCHAR(500) NULL,
    
    -- Common settings
    [TimeoutSeconds]  INT NOT NULL DEFAULT 30,
    [RetryCount]      INT NOT NULL DEFAULT 3,
    [CredentialsJson] NVARCHAR(MAX) NOT NULL,
    
    -- Audit
    [CreatedBy]       NVARCHAR(100) NOT NULL,
    [UpdatedBy]       NVARCHAR(100) NULL,
    [CreatedAt]       DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    [UpdatedAt]       DATETIME2 NULL,

    -- Soft delete
    [IsActive]        BIT NOT NULL DEFAULT (1),
    
    -- Concurrency
    [RowVersion]      ROWVERSION NOT NULL,
    
    CONSTRAINT [PK_AuthConfigs] 
        PRIMARY KEY NONCLUSTERED ([Guid]),
    CONSTRAINT [UX_AuthConfigs_Id] 
        UNIQUE CLUSTERED ([Id]),
    CONSTRAINT [UQ_AuthConfigs_Name] 
        UNIQUE ([Name]),
    CONSTRAINT [CK_AuthConfigs_AuthType] 
        CHECK ([AuthType] IN ('Basic', 'NTLM', 'SQL', 'Windows'))
);