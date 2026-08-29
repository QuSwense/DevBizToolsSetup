CREATE TABLE [dbo].[UserSettings] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [GlobalSettingId] INT NULL,
    [UserId] NVARCHAR(20) NOT NULL,
    [SettingValue] NVARCHAR(MAX) NOT NULL,
    [LastUpdatedAt] DATETIME NOT NULL CONSTRAINT DF_UserSettings_LastUpdatedAt DEFAULT GETDATE(),

    CONSTRAINT PK_UserSettings PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_UserSettings_User_GlobalSettingId_Key UNIQUE ([UserId] ASC, [GlobalSettingId] ASC),
    CONSTRAINT FK_UserSettings_GlobalSettings_GlobalSettingId FOREIGN KEY ([GlobalSettingId]) REFERENCES [dbo].[GlobalSettings]([Id]) ON DELETE SET NULL,

    CONSTRAINT FK_UserSettings_Users_UserId FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users]([UserId]) ON DELETE CASCADE
)
