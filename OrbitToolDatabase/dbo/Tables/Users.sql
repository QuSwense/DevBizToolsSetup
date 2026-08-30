/*
    Table: Users
    Description: Stores user information and their roles within the application.
*/
CREATE TABLE [dbo].[Users] (
    -- The AD User ID is used as the primary key to ensure uniqueness across the organization.
    -- Primary Key, Identity Column and Unique identifier
    [UserId] NVARCHAR(20) NOT NULL,
    -- User's email address, must be unique across all users
    [Email] NVARCHAR(250) NOT NULL,
    -- User's department within the organization, optional field
    [Department] NVARCHAR(100) NULL,
    -- User's first name, optional field
    [FirstName] NVARCHAR(100) NULL,
    -- User's last name, optional field
    [LastName] NVARCHAR(100) NULL,
    -- User's role within the application, optional field
    [Role] NVARCHAR(50) NULL,
    -- Indicates if the user is currently active, default is true
    [IsActive] BIT NOT NULL CONSTRAINT DF_Users_IsActive DEFAULT 1,
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT PK_Users PRIMARY KEY CLUSTERED ([UserId] ASC),
    CONSTRAINT UQ_Users_Email UNIQUE ([Email] ASC),
    CONSTRAINT CK_Users_Role CHECK ([Role] IS NULL OR [Role] IN (
        'Developer', 'TestEngineer', 'RequirementEngineer', 'ProjectManager', 'BusinessRepresentative'
    )),

    CONSTRAINT FK_Users_CreatedBy_Users FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_Users_LastUpdatedBy_Users FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
)
