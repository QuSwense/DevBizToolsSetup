/*
    Table: ServiceTestCases
    Description: This table represents service test cases.
*/
CREATE TABLE [dbo].[ServiceTestCases] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Name] NVARCHAR(200) NOT NULL,
    [ServiceRequestFileId] INT NULL,
    [IsActive] BIT NOT NULL CONSTRAINT DF_ServiceTestCases_IsActive DEFAULT 1,
    [RecordVersion] VARCHAR(50) NOT NULL
        CONSTRAINT DF_ServiceTestCases_RecordVersion DEFAULT ([dbo].[fn_CalculateVersion](NULL)),
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceTestCases_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    -- Primary Key
    CONSTRAINT PK_ServiceTestCases PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT CK_ServiceTestCases_RecordVersionFormat
        CHECK ([RecordVersion] LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9]'),

    -- Foreign Key
    CONSTRAINT FK_ServiceTestCases_ServiceRequestFiles_ServiceRequestFileId
        FOREIGN KEY ([ServiceRequestFileId]) REFERENCES [dbo].[ServiceRequestFiles]([Id]),
    CONSTRAINT FK_ServiceTestCases_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_ServiceTestCases_Users_LastUpdatedBy
        FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
)
