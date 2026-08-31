/*
    Table: ServiceTestSuites
    Description: This table represents service test suites. A service test suite can contain multiple service test cases and is used to group related tests together for execution and management purposes.
*/
CREATE TABLE [dbo].[ServiceTestSuites] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Name] NVARCHAR(200) NOT NULL,
    [Description] NVARCHAR(MAX) NULL,
    [IsActive] BIT NOT NULL CONSTRAINT DF_ServiceTestSuites_IsActive DEFAULT 1,
    [RecordVersion] VARCHAR(50) NOT NULL
        CONSTRAINT DF_ServiceTestSuites_RecordVersion DEFAULT ([dbo].[fn_CalculateVersion](NULL)),
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceTestSuites_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT PK_ServiceTestSuites PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_ServiceTestSuites_Name UNIQUE ([Name] ASC),
    CONSTRAINT CK_ServiceTestSuites_RecordVersionFormat
        CHECK ([RecordVersion] LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9]'),

    CONSTRAINT FK_ServiceTestSuites_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_ServiceTestSuites_Users_LastUpdatedBy
        FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
)
