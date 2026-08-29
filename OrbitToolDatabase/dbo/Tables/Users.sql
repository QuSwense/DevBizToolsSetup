CREATE TABLE [dbo].[Users] (
    [UserId] NVARCHAR(20) NOT NULL,
    [Email] NVARCHAR(250) NOT NULL,
    [Department] NVARCHAR(100) NULL,
    [FirstName] NVARCHAR(100) NULL,
    [LastName] NVARCHAR(100) NULL,
    [Role] NVARCHAR(50) NULL,
    [IsActive] BIT NOT NULL CONSTRAINT DF_Users_IsActive DEFAULT 1,
    [CreatedBy] NVARCHAR(20) NULL,
    [CreatedDate] DATETIME NOT NULL CONSTRAINT DF_Users_CreatedDate DEFAULT GETDATE(),
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT PK_Users PRIMARY KEY CLUSTERED ([UserId] ASC),
    CONSTRAINT UQ_Users_Email UNIQUE ([Email] ASC),
    CONSTRAINT CK_Users_Role CHECK ([Role] IS NULL OR [Role] IN (
        'Developer', 'Test Engineer', 'Requirement Engineer',
        'Team Leader', 'Project Manager', 'Business'
    )),

    CONSTRAINT FK_Users_CreatedBy_Users FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_Users_LastUpdatedBy_Users FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
)
