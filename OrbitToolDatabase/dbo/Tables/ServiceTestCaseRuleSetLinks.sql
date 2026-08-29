CREATE TABLE [dbo].[ServiceTestCaseRuleSetLinks] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [ServiceTestCaseId] INT NOT NULL,
    [RuleSetId] INT NOT NULL,
    [IsActive] BIT NOT NULL CONSTRAINT DF_ServiceTestCaseRuleSetLinks_IsActive DEFAULT 1,
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceTestCaseRuleSetLinks_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,

    -- Primary Key
    CONSTRAINT PK_ServiceTestCaseRuleSetLinks PRIMARY KEY CLUSTERED ([Id] ASC),

    -- Foreign Key
    CONSTRAINT FK_ServiceTestCaseRuleSetLinks_ServiceTestCases_ServiceTestCaseId
        FOREIGN KEY ([ServiceTestCaseId]) REFERENCES [dbo].[ServiceTestCases]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceTestCaseRuleSetLinks_RuleSets_RuleSetId
        FOREIGN KEY ([RuleSetId]) REFERENCES [dbo].[RuleSets]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceTestCaseRuleSetLinks_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId])
)
