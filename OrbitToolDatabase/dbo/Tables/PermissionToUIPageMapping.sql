/*
    Table: PermissionToUIPageMapping
    Description: Maps resource permissions to UI pages for dynamic UI rendering.
    Logic:
    - Links ResourcePermissions to UIPages
    - Enables conditional UI rendering based on permissions
    - Multiple permissions can grant access to a single page
*/
CREATE TABLE [dbo].[PermissionToUIPageMapping] (
    -- Primary Key
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Foreign Key to ResourcePermissions
    [ResourcePermissionId] BIGINT NOT NULL,
    -- Foreign Key to UIPages
    [UIPageId] INT NOT NULL,
    -- Access type: 'View', 'Edit', 'Full'
    [AccessType] NVARCHAR(20) NOT NULL DEFAULT 'View',
    -- Indicates if mapping is active
    [IsActive] BIT NOT NULL CONSTRAINT DF_PermissionToUIPageMapping_IsActive DEFAULT 1,
    -- Timestamps
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_PermissionToUIPageMapping_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT PK_PermissionToUIPageMapping PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_PermissionToUIPageMapping_Permission_Page UNIQUE ([ResourcePermissionId] ASC, [UIPageId] ASC),

    -- Foreign Keys
    CONSTRAINT FK_PermissionToUIPageMapping_ResourcePermissions FOREIGN KEY ([ResourcePermissionId]) 
        REFERENCES [dbo].[ResourcePermissions]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_PermissionToUIPageMapping_UIPages FOREIGN KEY ([UIPageId]) 
        REFERENCES [dbo].[UIPages]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_PermissionToUIPageMapping_Users_CreatedBy FOREIGN KEY ([CreatedBy]) 
        REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_PermissionToUIPageMapping_Users_LastUpdatedBy FOREIGN KEY ([LastUpdatedBy]) 
        REFERENCES [dbo].[Users]([UserId])
)
GO