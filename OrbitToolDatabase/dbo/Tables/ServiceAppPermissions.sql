/*
    Table: ServiceAppPermissions
    Description: Stores permissions for service applications, indicating which users have access to specific service applications and their corresponding access levels.
    Logic:
    - Share service applications with other users by granting them specific access levels (Read, Write, Execute).
*/
CREATE TABLE [dbo].[ServiceAppPermissions] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Public Identifier for UI/Secure Operations (GUID)
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_ServiceAppPermissions_PublicId DEFAULT NEWID(),
    -- Foreign Key to ServiceApplications table
    [ServiceApplicationId] INT NOT NULL,
    -- User ID, e.g., 'jdoe', 'asmith'
    [UserId] NVARCHAR(20) NOT NULL,
    -- Foreign Key to ResourcePermissions table, linking the user permission to a specific resource permission
    [ResourcePermissionId] BIGINT NOT NULL,
    -- Indicates if the permission is granted to the user, default is true
    [IsGranted] BIT NOT NULL CONSTRAINT DF_ServiceAppPermissions_IsGranted DEFAULT 1,
    -- Timestamps for auditing created and last updated
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_ServiceAppPermissions_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    -- Primary Key
    CONSTRAINT [PK_ServiceAppPermissions] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ_ServiceAppPermissions_PublicId] UNIQUE ([PublicId] ASC),
    CONSTRAINT [UQ_ServiceAppPermissions_ServiceApplicationId_UserId] UNIQUE ([ServiceApplicationId] ASC, [UserId] ASC, [ResourcePermissionId] ASC),

    -- Foreign Keys
    CONSTRAINT [FK_ServiceAppPermissions_ServiceApplications_ServiceApplicationId]
        FOREIGN KEY ([ServiceApplicationId]) REFERENCES [dbo].[ServiceApplications]([Id]) ON DELETE CASCADE,
    CONSTRAINT [FK_ServiceAppPermissions_Users_UserId]
        FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT [FK_ServiceAppPermissions_Users_LastUpdatedBy]
        FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT [FK_ServiceAppPermissions_Users_CreatedBy]
        FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId])
)
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX_ServiceAppPermissions_ServiceApplicationId_UserId]
    ON [dbo].[ServiceAppPermissions]([ServiceApplicationId] ASC, [UserId] ASC);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX_ServiceAppPermissions_ServiceApplicationId_UserId_ResourcePermissionId]
    ON [dbo].[ServiceAppPermissions]([ServiceApplicationId] ASC, [UserId] ASC, [ResourcePermissionId] ASC);
GO
