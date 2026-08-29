CREATE TABLE [dbo].[GlobalSettings] (
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Category] NVARCHAR(50) NOT NULL CONSTRAINT DF_GlobalSettings_Category DEFAULT 'General',
    [SettingKey] NVARCHAR(100) NOT NULL,
    [SettingValue] NVARCHAR(MAX) NOT NULL,
    [Description] NVARCHAR(500) NULL,
    [DataType] VARCHAR(20) NOT NULL CONSTRAINT DF_GlobalSettings_DataType DEFAULT 'String',
    [IsUserOverridable] BIT NOT NULL CONSTRAINT DF_GlobalSettings_IsUserOverridable DEFAULT 0,
    [IsActive] BIT NOT NULL CONSTRAINT DF_GlobalSettings_IsActive DEFAULT 1,
    [LastUpdatedAt] DATETIME NULL,
    [LastUpdatedBy] NVARCHAR(20) NULL,

    CONSTRAINT PK_GlobalSettings PRIMARY KEY CLUSTERED ([Id] ASC),
    -- Allowed Category values:
    -- 'General'       → Miscellaneous or default settings
    -- 'UI'            → Themes, branding, layout options
    -- 'Authentication'→ Login policies, token lifetimes, OAuth providers
    -- 'Authorization' → Role mappings, access control rules
    -- 'Database'      → Connection strings, timeout values
    -- 'Logging'       → Log levels, file paths, external log providers
    -- 'Email'         → SMTP server, sender address, templates
    -- 'API'           → Base URLs, API keys, rate limits
    -- 'Cache'         → Cache expiration, provider type (Redis, Memory)
    -- 'Security'      → Encryption algorithms, password policies, CORS rules
    -- 'FeatureFlags'  → Toggle experimental features on/off
    -- 'Localization'  → Default language, supported cultures
    -- 'Notifications' → Push/email/SMS notification preferences
    -- 'Performance'   → Thread pool limits, request throttling
    CONSTRAINT CK_GlobalSettings_Category CHECK (
        [Category] IN (
            'General',
            'UI',
            'Authentication',
            'Authorization',
            'Database',
            'Logging',
            'Email',
            'API',
            'Cache',
            'Security',
            'FeatureFlags',
            'Localization',
            'Notifications',
            'Performance'
        )
    ),
    CONSTRAINT UQ_GlobalSettings_SettingKey UNIQUE ([SettingKey] ASC),
    CONSTRAINT CK_GlobalSettings_DataType CHECK ([DataType] IN ('String', 'Integer', 'Decimal', 'Boolean', 'Json', 'Xml', 'DateTime')),

    CONSTRAINT FK_GlobalSettings_Users_LastUpdatedBy FOREIGN KEY ([LastUpdatedBy]) REFERENCES [dbo].[Users]([UserId])
)
