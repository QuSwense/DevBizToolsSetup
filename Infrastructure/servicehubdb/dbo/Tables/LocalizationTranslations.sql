-- ============================================
-- LOCALIZATION TRANSLATIONS TABLE
-- ============================================
-- User-editable translations for each language
-- ============================================

CREATE TABLE [dbo].[LocalizationTranslations] (
    [Id]              INT IDENTITY(1,1) NOT NULL,
    [Guid]            UNIQUEIDENTIFIER NOT NULL 
                      CONSTRAINT [DF_LocalizationTranslations_Guid] DEFAULT (NEWSEQUENTIALID()),
    
    [ResourceId]      INT NOT NULL,
    [LanguageId]      INT NOT NULL,
    [Value]           NVARCHAR(MAX) NOT NULL,
    
    -- Audit (who changed translations)
    [CreatedBy]       NVARCHAR(100) NOT NULL,
    [UpdatedBy]       NVARCHAR(100) NULL,
    [CreatedAt]       DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    [UpdatedAt]       DATETIME2 NULL,
    
    -- Concurrency
    [RowVersion]      ROWVERSION NOT NULL,
    
    CONSTRAINT [PK_LocalizationTranslations] 
        PRIMARY KEY NONCLUSTERED ([Guid]),
    CONSTRAINT [UX_LocalizationTranslations_Id] 
        UNIQUE CLUSTERED ([Id]),
    CONSTRAINT [UQ_LocalizationTranslations_Resource_Language] 
        UNIQUE ([ResourceId], [LanguageId]),
    CONSTRAINT [FK_LocalizationTranslations_Resource] 
        FOREIGN KEY ([ResourceId]) 
        REFERENCES [LocalizationResources]([Id]) 
        ON DELETE CASCADE,
    CONSTRAINT [FK_LocalizationTranslations_Language] 
        FOREIGN KEY ([LanguageId]) 
        REFERENCES [Languages]([Id]) 
        ON DELETE CASCADE
);