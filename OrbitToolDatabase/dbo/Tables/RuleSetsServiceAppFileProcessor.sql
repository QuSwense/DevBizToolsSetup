CREATE TABLE [dbo].[RuleSetsServiceAppFileProcessor]
(
    [Id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [ServiceApplicationId] INT NOT NULL,
    [RuleSetId] INT NOT NULL,
    [CreatedAt] DATETIME DEFAULT GETDATE(),

    CONSTRAINT [FK_RuleSetsServiceAppFileProcessor_ServiceApplication] FOREIGN KEY ([ServiceApplicationId]) REFERENCES [dbo].[ServiceApplication]([Id]),
    CONSTRAINT [FK_RuleSetsServiceAppFileProcessor_RuleSet] FOREIGN KEY ([RuleSetId]) REFERENCES [dbo].[RuleSet]([Id])
);