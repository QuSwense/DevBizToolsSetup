CREATE TABLE [dbo].[UserActivities] (
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    [UserId] NVARCHAR(20) NOT NULL,
    [FeatureActivitiesJson] NVARCHAR(MAX) NULL,
    [Timestamp] DATETIME NOT NULL CONSTRAINT DF_UserActivities_Timestamp DEFAULT GETDATE(),

    CONSTRAINT PK_UserActivities PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT CK_UserActivities_FeatureActivitiesJson CHECK ([FeatureActivitiesJson] IS NULL OR ISJSON([FeatureActivitiesJson]) = 1),

    CONSTRAINT FK_UserActivities_Users_UserId FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users]([UserId]) ON DELETE CASCADE
)
