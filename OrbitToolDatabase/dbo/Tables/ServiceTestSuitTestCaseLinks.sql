CREATE TABLE [dbo].[ServiceTestSuitTestCaseLinks] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [ServiceTestSuiteId] INT NOT NULL,
    [ServiceTestCaseId] INT NOT NULL,
    [ExecutionOrder] INT NOT NULL CONSTRAINT DF_TestCases_ExecutionOrder DEFAULT 1,
    [IsActive] BIT NOT NULL CONSTRAINT DF_TestCases_IsActive DEFAULT 1,
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_TestCases_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_ServiceTestSuitTestCaseLinks PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT FK_ServiceTestSuitTestCaseLinks_ServiceTestSuites_ServiceTestSuiteId
        FOREIGN KEY ([ServiceTestSuiteId]) REFERENCES [dbo].[ServiceTestSuites]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceTestSuitTestCaseLinks_ServiceTestCases_ServiceTestCaseId
        FOREIGN KEY ([ServiceTestCaseId]) REFERENCES [dbo].[ServiceTestCases]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceTestSuitTestCaseLinks_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId])
)
