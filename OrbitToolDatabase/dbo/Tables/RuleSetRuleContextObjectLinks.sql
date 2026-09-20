/*
    Table: RuleSetRuleContextObjectLinks
    Description: This table establishes a many-to-many relationship between RuleSets and RuleContextObjects.
                 Each entry links a specific RuleSet to a specific RuleContextObject, allowing for flexible
                 associations between rules and their applicable contexts.
    Logic: The table contains foreign keys to both the RuleSets and RuleContextObjects tables, ensuring referential integrity.
           It also includes audit fields to track creation and last update information for each link.
*/
CREATE TABLE [dbo].[RuleSetRuleContextObjectLinks] (
    -- Primary Key and Identity
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Public Identifier for UI/Secure Operations (GUID)
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_RuleSetRuleContextObjectLinks_PublicId DEFAULT NEWID(),
    -- Foreign Key References 
    [RuleSetId] INT NOT NULL,
    [InputOrOutputType] NVARCHAR(50) NOT NULL,
    -- Foreign Key References
    [RuleContextObjectId] INT NOT NULL,
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME2(3) NOT NULL CONSTRAINT DF_RuleSetRuleContextObjectLinks_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_RuleSetRuleContextObjectLinks PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT CK_RuleSetRuleContextObjectLinks_InputOrOutputType CHECK ([InputOrOutputType] IN ('Input', 'Output')),

    CONSTRAINT UQ_RuleSetRuleContextObjectLinks_PublicId UNIQUE ([PublicId] ASC),
    CONSTRAINT UQ_RuleSetRuleContextObjectLinks_RuleSetId_RuleContextObjectId_InputOrOutputType UNIQUE ([RuleSetId] ASC, [RuleContextObjectId] ASC, [InputOrOutputType] ASC),

    CONSTRAINT FK_RuleSetRuleContextObjectLinks_RuleSets FOREIGN KEY ([RuleSetId])
        REFERENCES [dbo].[RuleSets]([Id]),
    CONSTRAINT FK_RuleSetRuleContextObjectLinks_RuleSetContextObjects FOREIGN KEY ([RuleContextObjectId])
        REFERENCES [dbo].[RuleSetContextObjects]([Id]),
    CONSTRAINT FK_RuleSetRuleContextObjectLinks_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId])
);
GO

CREATE NONCLUSTERED INDEX IX_RuleSetRuleContextObjectLinks_RuleContextObjectId
    ON [dbo].[RuleSetRuleContextObjectLinks]([RuleContextObjectId] ASC)
GO
