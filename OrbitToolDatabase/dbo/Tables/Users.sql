/*
    Table: Users
    Description: Stores user information and their roles within the application.
    Logic:
    - Each user can have one role assigned
    - Role assignment determines default permissions
    - Individual permissions can override role-based permissions
*/
CREATE TABLE [dbo].[Users] (
    -- The AD User ID is used as the primary key to ensure uniqueness across the organization.
    [UserId] NVARCHAR(20) NOT NULL,
    -- User's email address, must be unique across all users
    [Email] NVARCHAR(250) NOT NULL,
    -- User's department within the organization, optional field
    [Department] NVARCHAR(100) NULL,
    -- User's first name, optional field
    [FirstName] NVARCHAR(100) NULL,
    -- User's last name, optional field
    [LastName] NVARCHAR(100) NULL,
    -- Foreign Key to Roles table (removed Role string column)
    [RoleId] INT NULL,
    -- Indicates if the user is currently active, default is true
    [IsActive] BIT NOT NULL CONSTRAINT DF_Users_IsActive DEFAULT 1,
    -- Timestamps for auditing
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT PK_Users PRIMARY KEY CLUSTERED ([UserId] ASC),
    CONSTRAINT UQ_Users_Email UNIQUE ([Email] ASC),

    -- Foreign Keys
    CONSTRAINT FK_Users_Roles_RoleId FOREIGN KEY ([RoleId]) REFERENCES [dbo].[Roles]([Id]) ON DELETE SET NULL,
    CONSTRAINT FK_Users_CreatedBy_Users FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_Users_LastUpdatedBy_Users FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
)
GO

CREATE NONCLUSTERED INDEX IX_Users_RoleId ON [dbo].[Users]([RoleId] ASC)
GO
