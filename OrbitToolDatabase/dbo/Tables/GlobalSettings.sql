/*
    Table: GlobalSettings
    Description: Stores global configuration settings for the application.
*/
CREATE TABLE [dbo].[GlobalSettings] (
    -- Primary Key, Identity Column and Unique identifier
    [Id] INT IDENTITY(1,1) NOT NULL,
    -- Public Identifier for UI/Secure Operations (GUID)
    [PublicId] UNIQUEIDENTIFIER NOT NULL 
        CONSTRAINT DF_GlobalSettings_PublicId DEFAULT NEWID(),
    -- Category of the setting, e.g., 'General', 'UI', 'Authentication', etc.
    [Category] NVARCHAR(50) NOT NULL CONSTRAINT DF_GlobalSettings_Category DEFAULT 'General',
    -- Key for the setting, must be unique across all settings
    [SettingKey] NVARCHAR(100) NOT NULL,
    -- Value of the setting, stored as NVARCHAR(MAX) to accommodate various data types
    [SettingValue] NVARCHAR(MAX) NOT NULL,
    -- Data type of the setting value, e.g., 
    -- 'String', 'Integer', 'Decimal', 'Boolean', 'Json', 'Xml', 'DateTime'
    [DataType] VARCHAR(20) NOT NULL CONSTRAINT DF_GlobalSettings_DataType DEFAULT 'String',
    -- Optional description for the setting
    [Description] NVARCHAR(500) NULL,
    -- Indicates if the setting can be overridden by users
    [IsUserOverridable] BIT NOT NULL CONSTRAINT DF_GlobalSettings_IsUserOverridable DEFAULT 0,
    -- Indicates if the setting is currently active
    [IsActive] BIT NOT NULL CONSTRAINT DF_GlobalSettings_IsActive DEFAULT 1,
    -- Timestamps for auditing
    [CreatedAt] DATETIME NOT NULL CONSTRAINT DF_GlobalSettings_CreatedAt DEFAULT GETDATE(),
    [CreatedBy] NVARCHAR(20) NOT NULL,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT PK_GlobalSettings PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT UQ_GlobalSettings_SettingKey UNIQUE ([SettingKey] ASC),
    CONSTRAINT UQ_GlobalSettings_PublicId UNIQUE ([PublicId] ASC),

    CONSTRAINT CK_GlobalSettings_DataType
        CHECK ([DataType] IN ('String', 'Integer', 'Decimal', 'Boolean', 'Json', 'Xml', 'DateTime')),

    -- Foreign Key Constraints for auditing
    CONSTRAINT FK_GlobalSettings_Users_CreatedBy FOREIGN KEY ([CreatedBy]) REFERENCES [dbo].[Users]([UserId]),
    CONSTRAINT FK_GlobalSettings_Users_LastUpdatedBy FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
)
