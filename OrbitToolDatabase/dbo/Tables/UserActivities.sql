/*
    Table: UserActivities
    Description: Stores user activity logs, including feature usage and timestamps.
    Logic:
    - The table should store various user activities with their respective details.
    - This is filled in by the application when a user performs an action that needs to be logged for auditing or analytics purposes.
*/
CREATE TABLE [dbo].[UserActivities] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    -- Foreign Key to Users table
    [UserId] NVARCHAR(20) NOT NULL,
    -- Type of activity performed by the user, e.g., 'Login', 'FeatureUsage'
    [ActivityType] NVARCHAR(100) NOT NULL,
    -- Optional action type for more granular activity categorization, e.g., 'Click', 'View', 'Edit'
    [ActionType] NVARCHAR(50) NULL,
    -- JSON string representing the activities performed by the user, including feature names and actions
    [FeatureActivitiesJson] NVARCHAR(MAX) NULL,
    -- Timestamp of when the activity was logged, defaulting to the current date and time
    [Timestamp] DATETIME NOT NULL CONSTRAINT DF_UserActivities_Timestamp DEFAULT GETDATE(),

    CONSTRAINT PK_UserActivities PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT CK_UserActivities_FeatureActivitiesJson CHECK ([FeatureActivitiesJson] IS NULL OR ISJSON([FeatureActivitiesJson]) = 1),

    CONSTRAINT FK_UserActivities_Users_UserId FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users]([UserId]) ON DELETE CASCADE
)
