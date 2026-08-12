-- ============================================
-- USERS TABLE
-- ============================================
-- Users can select their preferred language
-- LanguageId references the system-managed Languages table
-- ============================================

CREATE TABLE [dbo].[Users] (
    [LoginId]         NVARCHAR(100) NOT NULL,
    [Email]           NVARCHAR(200) NOT NULL,
    [DisplayName]     NVARCHAR(200) NOT NULL,
    
    -- Language preference (links to system Languages table)
    [LanguageId]      INT NOT NULL,  -- Default language assigned on user creation
    
    -- User profile
    [Department]      NVARCHAR(100) NULL,
    
    -- Status
    [IsActive]        BIT NOT NULL DEFAULT 1,
    [LastLoginAt]     DATETIME2 NULL,
    
    -- Audit
    [CreatedBy]       NVARCHAR(100) NOT NULL,
    [UpdatedBy]       NVARCHAR(100) NULL,
    [CreatedAt]       DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    [UpdatedAt]       DATETIME2 NULL,
    
    -- Concurrency
    [RowVersion]      ROWVERSION NOT NULL,
    
    CONSTRAINT [PK_Users] 
        PRIMARY KEY NONCLUSTERED ([LoginId]),
    CONSTRAINT [UQ_Users_Email] 
        UNIQUE ([Email]),
    CONSTRAINT [FK_Users_Language] 
        FOREIGN KEY ([LanguageId]) 
        REFERENCES [dbo].[Languages]([Id])
);

GO

-- Indexes
CREATE INDEX [IX_Users_LanguageId] ON [Users]([LanguageId]);
GO