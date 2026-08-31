/*
    Table: RuleSetContextObjectLinks
    Description: This table establishes a many-to-many relationship between RuleSets and RuleContextObjects.
                 Each entry links a specific RuleSet to a specific RuleContextObject, allowing for flexible
                 associations between rules and their applicable contexts.
    Logic: The table contains foreign keys to both the RuleSets and RuleContextObjects tables, ensuring referential integrity.
           It also includes audit fields to track creation and last update information for each link.
*/
CREATE TABLE [dbo].[RuleSetContextObjectLinks] (
    -- Primary Key and Identity
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Foreign Key References 
    [RuleSetId] INT NOT NULL,
    -- Foreign Key References
    [RuleContextObjectId] INT NOT NULL,
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_RuleSetContextObjectLinks_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT PK_RuleSetContextObjectLinks PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UIX_RuleSetContextObjectLinks_RuleSetId_RuleContextObjectId UNIQUE ([RuleSetId] ASC, [RuleContextObjectId] ASC),

    CONSTRAINT FK_RuleSetContextObjectLinks_RuleSets FOREIGN KEY ([RuleSetId])
        REFERENCES [dbo].[RuleSets]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_RuleSetContextObjectLinks_RuleContextObjects FOREIGN KEY ([RuleContextObjectId])
        REFERENCES [dbo].[RuleContextObjects]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_RuleSetContextObjectLinks_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_RuleSetContextObjectLinks_Users_LastUpdatedBy
        FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
)
