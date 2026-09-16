/*
    Table: ServiceTestCaseRuleSetLinks
    Description: This table represents the many-to-many relationship between ServiceTestCases and RuleSets.
*/
CREATE TABLE [dbo].[ServiceTestCaseRuleSetLinks] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Public Identifier for UI/Secure Operations (GUID)
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_ServiceTestCaseRuleSetLinks_PublicId DEFAULT NEWID(),
    [ServiceTestCaseId] INT NOT NULL,
    [RuleSetId] INT NOT NULL,
    [IsActive] BIT NOT NULL CONSTRAINT DF_ServiceTestCaseRuleSetLinks_IsActive DEFAULT 1,
    [CreatedAt] DATETIME2(3) NOT NULL CONSTRAINT DF_ServiceTestCaseRuleSetLinks_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,

    -- Primary Key
    CONSTRAINT PK_ServiceTestCaseRuleSetLinks PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_ServiceTestCaseRuleSetLinks_PublicId UNIQUE ([PublicId] ASC),
    CONSTRAINT UQ_ServiceTestCaseRuleSetLinks_Case_Set UNIQUE ([ServiceTestCaseId] ASC, [RuleSetId] ASC),

    -- Foreign Key
    CONSTRAINT FK_ServiceTestCaseRuleSetLinks_ServiceTestCases_ServiceTestCaseId
        FOREIGN KEY ([ServiceTestCaseId]) REFERENCES [dbo].[ServiceTestCases]([Id]),
    CONSTRAINT FK_ServiceTestCaseRuleSetLinks_RuleSets_RuleSetId
        FOREIGN KEY ([RuleSetId]) REFERENCES [dbo].[RuleSets]([Id]),
    CONSTRAINT FK_ServiceTestCaseRuleSetLinks_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId])
);
GO

CREATE NONCLUSTERED INDEX IX_ServiceTestCaseRuleSetLinks_RuleSetId
    ON [dbo].[ServiceTestCaseRuleSetLinks]([RuleSetId] ASC)
GO
