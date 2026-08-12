-- ============================================
-- LOCALIZATION RESOURCES TABLE
-- ============================================
-- System-defined resources with default values
-- ============================================

CREATE TABLE [dbo].[LocalizationResources] (
    [Id]              INT IDENTITY(1,1) NOT NULL,
    [Guid]            UNIQUEIDENTIFIER NOT NULL DEFAULT (NEWSEQUENTIALID()),
    
    -- Resource key
    [ResourceKey]     NVARCHAR(200) NOT NULL,
    
    -- Category
    [CategoryName]    NVARCHAR(50) NOT NULL,
    [SubcategoryName]        NVARCHAR(50) NULL,
    
    -- Default value (English fallback)
    [DefaultValue]    NVARCHAR(MAX) NOT NULL,
    
    -- Description for admins
    [Description]     NVARCHAR(500) NULL,
    
    -- Status
    [IsActive]        BIT NOT NULL DEFAULT 1,

    [CreatedBy]       NVARCHAR(100) NOT NULL,
    [UpdatedBy]       NVARCHAR(100) NULL,
    [CreatedAt]       DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    [UpdatedAt]       DATETIME2 NULL,
    
    -- No audit columns (system-managed)
    
    CONSTRAINT [PK_LocalizationResources] 
        PRIMARY KEY NONCLUSTERED ([Guid]),
    CONSTRAINT [UX_LocalizationResources_Id] 
        UNIQUE CLUSTERED ([Id]),
    CONSTRAINT [UQ_LocalizationResources_Key] 
        UNIQUE ([ResourceKey])
);