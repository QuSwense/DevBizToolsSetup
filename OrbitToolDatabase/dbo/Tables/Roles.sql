/*
    Table: Roles
    Description: Stores role definitions that can be assigned to users. Includes system-defined roles and custom roles created by users.
    Logic:
    - System roles: 'Developer', 'Admin', 'Viewer' (seeded by default)
    - Custom roles: Can be created by users with appropriate permissions
    - IsSystemRole flag prevents deletion/modification of system roles
*/
CREATE TABLE [dbo].[Roles] (
    -- Primary Key, Identity Column
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Public Identifier for UI/Secure Operations (GUID)
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_Roles_PublicId DEFAULT NEWID(),
    -- Role name, must be unique
    [Name] NVARCHAR(50) NOT NULL,
    -- Role description
    [Description] NVARCHAR(500) NULL,
    -- Indicates if this is a system-defined role (cannot be deleted/modified)
    [IsSystemRole] BIT NOT NULL CONSTRAINT DF_Roles_IsSystemRole DEFAULT 0,
    -- Indicates if the role is active
    [IsActive] BIT NOT NULL CONSTRAINT DF_Roles_IsActive DEFAULT 1,
    -- Timestamps for auditing
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_Roles_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT PK_Roles PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_Roles_PublicId UNIQUE ([PublicId] ASC),
    CONSTRAINT UQ_Roles_Name UNIQUE ([Name] ASC),

    -- Foreign Keys
    CONSTRAINT FK_Roles_Users_CreatedBy FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_Roles_Users_LastUpdatedBy FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
)
GO

CREATE NONCLUSTERED INDEX IX_Roles_Name ON [dbo].[Roles]([Name] ASC)
GO

CREATE NONCLUSTERED INDEX IX_Roles_IsActive ON [dbo].[Roles]([IsActive] ASC)
GO

-- System-role seed data lives in Seeds/RolesSeed.sql (wired as PostDeploy in the
-- sqlproj) so this table file remains a valid model object (INSERT DML is not
-- allowed in table files).
GO
