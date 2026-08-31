/*
    Table: ServiceTestSuiteTestCaseLinks
    Description: This table links service test suites to individual test cases, allowing for the organization and execution of test cases within a suite. It includes execution order, active status, and audit information for tracking changes.
*/
CREATE TABLE [dbo].[ServiceTestSuiteTestCaseLinks] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [ServiceTestSuiteId] INT NOT NULL,
    [ServiceTestCaseId] INT NOT NULL,
    [ExecutionOrder] INT NOT NULL CONSTRAINT DF_ServiceTestSuiteTestCaseLinks_ExecutionOrder DEFAULT 1,
    [IsActive] BIT NOT NULL CONSTRAINT DF_ServiceTestSuiteTestCaseLinks_IsActive DEFAULT 1,
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceTestSuiteTestCaseLinks_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,

    CONSTRAINT PK_ServiceTestSuiteTestCaseLinks PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT FK_ServiceTestSuiteTestCaseLinks_ServiceTestSuites_ServiceTestSuiteId
        FOREIGN KEY ([ServiceTestSuiteId]) REFERENCES [dbo].[ServiceTestSuites]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceTestSuiteTestCaseLinks_ServiceTestCases_ServiceTestCaseId
        FOREIGN KEY ([ServiceTestCaseId]) REFERENCES [dbo].[ServiceTestCases]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_ServiceTestSuiteTestCaseLinks_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId])
)
