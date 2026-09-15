/*
    Table: UserSettings
    Description: Stores user-specific configuration settings that can override global settings.
*/
CREATE TABLE [dbo].[UserSettings] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Public Identifier for UI/Secure Operations (GUID)
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_UserSettings_PublicId DEFAULT NEWID(),
    -- Foreign Key to GlobalSettings table
    [GlobalSettingId] INT NULL,
    -- Foreign Key to Users table
    [UserId] NVARCHAR(20) NOT NULL,
    -- Value of the user-specific setting, stored as NVARCHAR(MAX) to accommodate various data types
    [SettingValue] NVARCHAR(MAX) NOT NULL,
    -- Timestamps for auditing last updated
    [LastUpdatedAt] DATETIME NOT NULL CONSTRAINT DF_UserSettings_LastUpdatedAt DEFAULT GETDATE(),

    CONSTRAINT PK_UserSettings PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_UserSettings_PublicId UNIQUE ([PublicId] ASC),

    -- Foreign Key Constraints
    CONSTRAINT FK_UserSettings_GlobalSettings_GlobalSettingId FOREIGN KEY ([GlobalSettingId]) REFERENCES [dbo].[GlobalSettings]([Id]) ON DELETE SET NULL,
    CONSTRAINT FK_UserSettings_Users_UserId FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users]([UserId]) ON DELETE CASCADE
)
GO

-- Uniqueness: GlobalSettingId is nullable, so a plain UNIQUE over it does not enforce
-- uniqueness (NULLs compare as distinct). Filtered index enforces it for real rows.
CREATE UNIQUE NONCLUSTERED INDEX UX_UserSettings_User_GlobalSetting
    ON [dbo].[UserSettings]([UserId] ASC, [GlobalSettingId] ASC)
    WHERE [GlobalSettingId] IS NOT NULL
GO

CREATE NONCLUSTERED INDEX IX_UserSettings_GlobalSettingId
    ON [dbo].[UserSettings]([GlobalSettingId] ASC)
GO
