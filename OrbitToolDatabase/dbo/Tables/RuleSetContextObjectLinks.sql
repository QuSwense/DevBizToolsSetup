CREATE TABLE [dbo].[RuleSetContextObjectLinks] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [RuleSetId] INT NOT NULL,
    [RuleContextObjectId] INT NOT NULL,
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_RuleSetContextObjectLinks_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT PK_RuleSetContextObjectLinks PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT FK_RuleSetContextObjectLinks_RuleSets FOREIGN KEY ([RuleSetId])
        REFERENCES [dbo].[RuleSets]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_RuleSetContextObjectLinks_RuleContextObjects FOREIGN KEY ([RuleContextObjectId])
        REFERENCES [dbo].[RuleContextObjects]([Id]) ON DELETE CASCADE
)
