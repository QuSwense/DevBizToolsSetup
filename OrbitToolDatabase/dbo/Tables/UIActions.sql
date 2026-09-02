/*
    Table: UIActions
    Description: Defines UI actions/operations that require specific permissions.
    Logic:
    - Each action corresponds to a specific UI element (button, menu item, etc.)
    - Actions are linked to pages and require specific permissions
*/
CREATE TABLE [dbo].[UIActions] (
    -- Primary Key, Identity Column
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Public Identifier
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_UIActions_PublicId DEFAULT NEWID(),
    -- Foreign Key to UIPages
    [PageId] INT NOT NULL,
    -- Action Name (e.g., 'Create', 'Edit', 'Delete', 'Share', 'Execute', 'Export')
    [ActionName] NVARCHAR(50) NOT NULL,
    -- Display name for the action (e.g., 'Create New', 'Edit', 'Delete')
    [DisplayName] NVARCHAR(100) NOT NULL,
    -- Required permission for this action
    [RequiredPermissionKey] NVARCHAR(100) NOT NULL,
    -- Action type (e.g., 'Button', 'MenuItem', 'Tab', 'Link')
    [ActionType] NVARCHAR(20) NOT NULL DEFAULT 'Button',
    -- CSS/UI identifier for the element
    [UiElementId] NVARCHAR(100) NULL,
    -- Indicates if action is active
    [IsActive] BIT NOT NULL CONSTRAINT DF_UIActions_IsActive DEFAULT 1,
    -- Timestamps for auditing
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_UIActions_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT PK_UIActions PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_UIActions_PublicId UNIQUE ([PublicId] ASC),
    CONSTRAINT UQ_UIActions_PageId_ActionName UNIQUE ([PageId] ASC, [ActionName] ASC),

    -- Foreign Keys
    CONSTRAINT FK_UIActions_UIPages_PageId FOREIGN KEY ([PageId]) REFERENCES [dbo].[UIPages]([Id]) ON DELETE CASCADE,
    CONSTRAINT FK_UIActions_Users_CreatedBy FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_UIActions_Users_LastUpdatedBy FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
)
GO