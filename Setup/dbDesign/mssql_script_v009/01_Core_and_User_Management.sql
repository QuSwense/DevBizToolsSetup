-- ==========================================
-- 01: Core Infrastructure, Users & Auditing
-- ==========================================
IF NOT EXISTS (SELECT [name] FROM [sys].[databases] WHERE [name] = N'OrbitTool')
BEGIN
    CREATE DATABASE [OrbitTool];
END
GO

USE [OrbitTool];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE FUNCTION dbo.fn_CalculateVersion (@PreviousVersion VARCHAR(50))
RETURNS VARCHAR(50)
AS
BEGIN
    DECLARE @Quarter INT, @YearSuffix VARCHAR(2), @NewNN INT, @Result VARCHAR(50);

    -- Calculate current quarter (Jan–Mar = 01, Apr–Jun = 02, Jul–Sep = 03, Oct–Dec = 04)
    SET @Quarter = DATEPART(QUARTER, GETDATE());
    SET @YearSuffix = RIGHT(CONVERT(VARCHAR(4), YEAR(GETDATE())), 2);

    IF @PreviousVersion IS NULL
    BEGIN
        SET @Result = RIGHT('0' + CAST(@Quarter AS VARCHAR(2)), 2) + '.' + @YearSuffix + '.01';
    END
    ELSE
    BEGIN
        DECLARE @PrevQuarter VARCHAR(2), @PrevYear VARCHAR(2), @PrevNN INT;

        SET @PrevQuarter = LEFT(@PreviousVersion, 2);
        SET @PrevYear = SUBSTRING(@PreviousVersion, 4, 2);
        SET @PrevNN = CAST(RIGHT(@PreviousVersion, 2) AS INT);

        IF @PrevQuarter <> RIGHT('0' + CAST(@Quarter AS VARCHAR(2)), 2)
           OR @PrevYear <> @YearSuffix
        BEGIN
            -- New quarter or year → reset NN
            SET @Result = RIGHT('0' + CAST(@Quarter AS VARCHAR(2)), 2) + '.' + @YearSuffix + '.01';
        END
        ELSE
        BEGIN
            -- Same quarter/year → increment NN
            SET @NewNN = @PrevNN + 1;
            SET @Result = @PrevQuarter + '.' + @PrevYear + '.' + RIGHT('0' + CAST(@NewNN AS VARCHAR(2)), 2);
        END
    END

    RETURN @Result;
END;
GO

-- Users Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'Users' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[Users] (
        [UserId] NVARCHAR(20) NOT NULL,
        [Email] NVARCHAR(250) NOT NULL,
        [Department] NVARCHAR(100) NULL,
        [FirstName] NVARCHAR(100) NULL,
        [LastName] NVARCHAR(100) NULL,
        [Role] NVARCHAR(50) NULL,
        [IsActive] BIT NOT NULL CONSTRAINT DF_Users_IsActive DEFAULT 1,
        [CreatedBy] NVARCHAR(20) NULL,
        [CreatedDate] DATETIME NOT NULL CONSTRAINT DF_Users_CreatedDate DEFAULT GETDATE(),
        [LastUpdatedAt] DATETIME NULL,
        [LastUpdatedBy] NVARCHAR(20) NULL,

        CONSTRAINT PK_Users PRIMARY KEY CLUSTERED ([UserId] ASC),
        CONSTRAINT UQ_Users_Email UNIQUE ([Email] ASC),
        CONSTRAINT CK_Users_Role CHECK ([Role] IS NULL OR [Role] IN (
            'Developer', 'Test Engineer', 'Requirement Engineer',
            'Team Leader', 'Project Manager', 'Business'
        )),

        CONSTRAINT FK_Users_CreatedBy_Users FOREIGN KEY ([CreatedBy]) REFERENCES dbo.[Users]([UserId]),
        CONSTRAINT FK_Users_LastUpdatedBy_Users FOREIGN KEY ([LastUpdatedBy]) REFERENCES dbo.[Users]([UserId])
    );
END
GO

-- UserActivities Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'UserActivities' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[UserActivities] (
        [Id] BIGINT IDENTITY(1,1) NOT NULL,
        [UserId] NVARCHAR(20) NOT NULL,
        [FeatureActivitiesJson] NVARCHAR(MAX) NULL,
        [Timestamp] DATETIME NOT NULL CONSTRAINT DF_UserActivities_Timestamp DEFAULT GETDATE(),

        CONSTRAINT PK_UserActivities PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT CK_UserActivities_FeatureActivitiesJson CHECK ([FeatureActivitiesJson] IS NULL OR ISJSON([FeatureActivitiesJson]) = 1),

        CONSTRAINT FK_UserActivities_Users_UserId FOREIGN KEY ([UserId]) REFERENCES dbo.[Users]([UserId]) ON DELETE CASCADE
    );
END
GO

-- GlobalSettings Table
-- 
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'GlobalSettings' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[GlobalSettings] (
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
        
        CONSTRAINT FK_GlobalSettings_Users_LastUpdatedBy FOREIGN KEY ([LastUpdatedBy]) REFERENCES dbo.[Users]([UserId])
    );
END
GO

-- UserSettings Table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = N'UserSettings' AND schema_id = SCHEMA_ID(N'dbo'))
BEGIN
    CREATE TABLE dbo.[UserSettings] (
        [Id] INT IDENTITY(1,1) NOT NULL,
        [GlobalSettingId] INT NULL,
        [UserId] NVARCHAR(20) NOT NULL,
        [SettingValue] NVARCHAR(MAX) NOT NULL,
        [LastUpdatedAt] DATETIME NOT NULL CONSTRAINT DF_UserSettings_LastUpdatedAt DEFAULT GETDATE(),

        CONSTRAINT PK_UserSettings PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT UQ_UserSettings_User_GlobalSettingId_Key UNIQUE ([UserId] ASC, [GlobalSettingId] ASC),
        CONSTRAINT FK_UserSettings_GlobalSettings_GlobalSettingId FOREIGN KEY ([GlobalSettingId]) REFERENCES dbo.[GlobalSettings]([Id]) ON DELETE SET NULL,

        CONSTRAINT FK_UserSettings_Users_UserId FOREIGN KEY ([UserId]) REFERENCES dbo.[Users]([UserId]) ON DELETE CASCADE
    );
END
GO
