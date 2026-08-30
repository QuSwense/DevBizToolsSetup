/*
    ResourcePermissions Table
    This table stores the permissions associated with various resources in the system.
    Each permission is identified by a unique key and is linked to the user who created or last updated it.
*/
CREATE TABLE [dbo].[ResourcePermissions]
(
    -- Primary Key, Identity Column and Unique identifier
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    -- Public Identifier for UI/Secure Operations (GUID)
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_ResourcePermissions_PublicId DEFAULT NEWID(),
    -- string representing the permission key e.g., 'soapapplication:add', 'restapi:delete', etc.
    [PermissionKey] NVARCHAR(MAX) NULL,
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_ResourcePermissions_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT PK_ResourcePermissions PRIMARY KEY ([Id]),

    CONSTRAINT FK_ResourcePermissions_Users_CreatedBy FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_ResourcePermissions_Users_LastUpdatedBy FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
);
