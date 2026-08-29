CREATE TABLE [dbo].[ServiceTestCases] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Name] NVARCHAR(200) NOT NULL,
    [ServiceRequestFileId] INT NOT NULL,
    [IsActive] BIT NOT NULL CONSTRAINT DF_ServiceTestCases_IsActive DEFAULT 1,
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceTestCases_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    -- Primary Key
    CONSTRAINT PK_ServiceTestCases PRIMARY KEY CLUSTERED ([Id] ASC),

    -- Foreign Key
    CONSTRAINT FK_ServiceTestCases_Users_CreatedBy
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_ServiceTestCases_Users_LastUpdatedBy
        FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
)
