/*
    Seed GlobalSettings - Application-wide configuration settings

    Idempotent: each setting is inserted only if a setting with that SettingKey does not exist.
    NOTE: The SYSTEM user must exist before running this script.
*/
SET NOCOUNT ON;
GO

-- ============================================
-- General Settings
-- ============================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[GlobalSettings] WHERE [SettingKey] = 'Application.Name')
    INSERT INTO [dbo].[GlobalSettings] ([Category], [SettingKey], [SettingValue], [DataType], [Description], [IsUserOverridable], [CreatedBy])
    VALUES ('General', 'Application.Name', 'OrbitHub', 'String', 'Application display name', 0, 'SYSTEM');
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[GlobalSettings] WHERE [SettingKey] = 'Application.Version')
    INSERT INTO [dbo].[GlobalSettings] ([Category], [SettingKey], [SettingValue], [DataType], [Description], [IsUserOverridable], [CreatedBy])
    VALUES ('General', 'Application.Version', '1.0.0', 'String', 'Current application version', 0, 'SYSTEM');
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[GlobalSettings] WHERE [SettingKey] = 'Application.DefaultCulture')
    INSERT INTO [dbo].[GlobalSettings] ([Category], [SettingKey], [SettingValue], [DataType], [Description], [IsUserOverridable], [CreatedBy])
    VALUES ('General', 'Application.DefaultCulture', 'en-US', 'String', 'Default culture/locale for the application', 1, 'SYSTEM');
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[GlobalSettings] WHERE [SettingKey] = 'Application.Timezone')
    INSERT INTO [dbo].[GlobalSettings] ([Category], [SettingKey], [SettingValue], [DataType], [Description], [IsUserOverridable], [CreatedBy])
    VALUES ('General', 'Application.Timezone', 'UTC', 'String', 'Default timezone for the application', 1, 'SYSTEM');
GO

-- ============================================
-- UI Settings
-- ============================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[GlobalSettings] WHERE [SettingKey] = 'UI.Sidebar.DefaultState')
    INSERT INTO [dbo].[GlobalSettings] ([Category], [SettingKey], [SettingValue], [DataType], [Description], [IsUserOverridable], [CreatedBy])
    VALUES ('UI', 'UI.Sidebar.DefaultState', 'expanded', 'String', 'Default sidebar state: expanded or collapsed', 1, 'SYSTEM');
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[GlobalSettings] WHERE [SettingKey] = 'UI.Theme.Default')
    INSERT INTO [dbo].[GlobalSettings] ([Category], [SettingKey], [SettingValue], [DataType], [Description], [IsUserOverridable], [CreatedBy])
    VALUES ('UI', 'UI.Theme.Default', 'light', 'String', 'Default UI theme: light or dark', 1, 'SYSTEM');
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[GlobalSettings] WHERE [SettingKey] = 'UI.Pagination.PageSize')
    INSERT INTO [dbo].[GlobalSettings] ([Category], [SettingKey], [SettingValue], [DataType], [Description], [IsUserOverridable], [CreatedBy])
    VALUES ('UI', 'UI.Pagination.PageSize', '25', 'Integer', 'Default number of records per page in tables', 1, 'SYSTEM');
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[GlobalSettings] WHERE [SettingKey] = 'UI.Pagination.MaxPageSize')
    INSERT INTO [dbo].[GlobalSettings] ([Category], [SettingKey], [SettingValue], [DataType], [Description], [IsUserOverridable], [CreatedBy])
    VALUES ('UI', 'UI.Pagination.MaxPageSize', '100', 'Integer', 'Maximum allowed records per page', 0, 'SYSTEM');
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[GlobalSettings] WHERE [SettingKey] = 'UI.DateFormat')
    INSERT INTO [dbo].[GlobalSettings] ([Category], [SettingKey], [SettingValue], [DataType], [Description], [IsUserOverridable], [CreatedBy])
    VALUES ('UI', 'UI.DateFormat', 'yyyy-MM-dd', 'String', 'Default date display format', 1, 'SYSTEM');
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[GlobalSettings] WHERE [SettingKey] = 'UI.DateTimeFormat')
    INSERT INTO [dbo].[GlobalSettings] ([Category], [SettingKey], [SettingValue], [DataType], [Description], [IsUserOverridable], [CreatedBy])
    VALUES ('UI', 'UI.DateTimeFormat', 'yyyy-MM-dd HH:mm:ss', 'String', 'Default date-time display format', 1, 'SYSTEM');
GO

-- ============================================
-- Authentication Settings
-- ============================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[GlobalSettings] WHERE [SettingKey] = 'Auth.SessionTimeoutMinutes')
    INSERT INTO [dbo].[GlobalSettings] ([Category], [SettingKey], [SettingValue], [DataType], [Description], [IsUserOverridable], [CreatedBy])
    VALUES ('Authentication', 'Auth.SessionTimeoutMinutes', '60', 'Integer', 'Session idle timeout in minutes', 0, 'SYSTEM');
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[GlobalSettings] WHERE [SettingKey] = 'Auth.MaxLoginAttempts')
    INSERT INTO [dbo].[GlobalSettings] ([Category], [SettingKey], [SettingValue], [DataType], [Description], [IsUserOverridable], [CreatedBy])
    VALUES ('Authentication', 'Auth.MaxLoginAttempts', '5', 'Integer', 'Maximum failed login attempts before lockout', 0, 'SYSTEM');
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[GlobalSettings] WHERE [SettingKey] = 'Auth.LockoutDurationMinutes')
    INSERT INTO [dbo].[GlobalSettings] ([Category], [SettingKey], [SettingValue], [DataType], [Description], [IsUserOverridable], [CreatedBy])
    VALUES ('Authentication', 'Auth.LockoutDurationMinutes', '15', 'Integer', 'Account lockout duration in minutes', 0, 'SYSTEM');
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[GlobalSettings] WHERE [SettingKey] = 'Auth.PasswordMinLength')
    INSERT INTO [dbo].[GlobalSettings] ([Category], [SettingKey], [SettingValue], [DataType], [Description], [IsUserOverridable], [CreatedBy])
    VALUES ('Authentication', 'Auth.PasswordMinLength', '8', 'Integer', 'Minimum password length requirement', 0, 'SYSTEM');
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[GlobalSettings] WHERE [SettingKey] = 'Auth.RequireMfa')
    INSERT INTO [dbo].[GlobalSettings] ([Category], [SettingKey], [SettingValue], [DataType], [Description], [IsUserOverridable], [CreatedBy])
    VALUES ('Authentication', 'Auth.RequireMfa', 'false', 'Boolean', 'Whether multi-factor authentication is required', 0, 'SYSTEM');
GO

-- ============================================
-- Service Execution Settings
-- ============================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[GlobalSettings] WHERE [SettingKey] = 'Service.RequestTimeoutSeconds')
    INSERT INTO [dbo].[GlobalSettings] ([Category], [SettingKey], [SettingValue], [DataType], [Description], [IsUserOverridable], [CreatedBy])
    VALUES ('Service', 'Service.RequestTimeoutSeconds', '30', 'Integer', 'Default timeout for service requests in seconds', 0, 'SYSTEM');
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[GlobalSettings] WHERE [SettingKey] = 'Service.MaxFileSizeMb')
    INSERT INTO [dbo].[GlobalSettings] ([Category], [SettingKey], [SettingValue], [DataType], [Description], [IsUserOverridable], [CreatedBy])
    VALUES ('Service', 'Service.MaxFileSizeMb', '10', 'Integer', 'Maximum allowed file upload size in MB', 0, 'SYSTEM');
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[GlobalSettings] WHERE [SettingKey] = 'Service.CompressionAlgorithm')
    INSERT INTO [dbo].[GlobalSettings] ([Category], [SettingKey], [SettingValue], [DataType], [Description], [IsUserOverridable], [CreatedBy])
    VALUES ('Service', 'Service.CompressionAlgorithm', 'Zstandard', 'String', 'Default compression algorithm for stored files', 0, 'SYSTEM');
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[GlobalSettings] WHERE [SettingKey] = 'Service.RuleEngine.MaxExecutionTimeMs')
    INSERT INTO [dbo].[GlobalSettings] ([Category], [SettingKey], [SettingValue], [DataType], [Description], [IsUserOverridable], [CreatedBy])
    VALUES ('Service', 'Service.RuleEngine.MaxExecutionTimeMs', '5000', 'Integer', 'Maximum rule execution time in milliseconds', 0, 'SYSTEM');
GO

-- ============================================
-- Indexing Settings
-- ============================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[GlobalSettings] WHERE [SettingKey] = 'Indexing.Enabled')
    INSERT INTO [dbo].[GlobalSettings] ([Category], [SettingKey], [SettingValue], [DataType], [Description], [IsUserOverridable], [CreatedBy])
    VALUES ('Indexing', 'Indexing.Enabled', 'true', 'Boolean', 'Whether background file indexing is enabled', 0, 'SYSTEM');
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[GlobalSettings] WHERE [SettingKey] = 'Indexing.BatchSize')
    INSERT INTO [dbo].[GlobalSettings] ([Category], [SettingKey], [SettingValue], [DataType], [Description], [IsUserOverridable], [CreatedBy])
    VALUES ('Indexing', 'Indexing.BatchSize', '50', 'Integer', 'Number of files to process per indexing batch', 0, 'SYSTEM');
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[GlobalSettings] WHERE [SettingKey] = 'Indexing.MaxConcurrentJobs')
    INSERT INTO [dbo].[GlobalSettings] ([Category], [SettingKey], [SettingValue], [DataType], [Description], [IsUserOverridable], [CreatedBy])
    VALUES ('Indexing', 'Indexing.MaxConcurrentJobs', '4', 'Integer', 'Maximum concurrent indexing jobs', 0, 'SYSTEM');
GO

-- ============================================
-- Logging & Monitoring Settings
-- ============================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[GlobalSettings] WHERE [SettingKey] = 'Logging.RetentionDays')
    INSERT INTO [dbo].[GlobalSettings] ([Category], [SettingKey], [SettingValue], [DataType], [Description], [IsUserOverridable], [CreatedBy])
    VALUES ('Logging', 'Logging.RetentionDays', '90', 'Integer', 'Number of days to retain activity logs', 0, 'SYSTEM');
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[GlobalSettings] WHERE [SettingKey] = 'Logging.AuditLevel')
    INSERT INTO [dbo].[GlobalSettings] ([Category], [SettingKey], [SettingValue], [DataType], [Description], [IsUserOverridable], [CreatedBy])
    VALUES ('Logging', 'Logging.AuditLevel', 'Information', 'String', 'Minimum audit log level: Error, Warning, Information, Debug', 0, 'SYSTEM');
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[GlobalSettings] WHERE [SettingKey] = 'Monitoring.HealthCheckIntervalSeconds')
    INSERT INTO [dbo].[GlobalSettings] ([Category], [SettingKey], [SettingValue], [DataType], [Description], [IsUserOverridable], [CreatedBy])
    VALUES ('Monitoring', 'Monitoring.HealthCheckIntervalSeconds', '60', 'Integer', 'Interval between health check pings in seconds', 0, 'SYSTEM');
GO

-- ============================================
-- Feature Flags
-- ============================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[GlobalSettings] WHERE [SettingKey] = 'Feature.EnableAdminModule')
    INSERT INTO [dbo].[GlobalSettings] ([Category], [SettingKey], [SettingValue], [DataType], [Description], [IsUserOverridable], [CreatedBy])
    VALUES ('Feature', 'Feature.EnableAdminModule', 'true', 'Boolean', 'Whether the Administration module is enabled', 0, 'SYSTEM');
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[GlobalSettings] WHERE [SettingKey] = 'Feature.EnableFileIndexing')
    INSERT INTO [dbo].[GlobalSettings] ([Category], [SettingKey], [SettingValue], [DataType], [Description], [IsUserOverridable], [CreatedBy])
    VALUES ('Feature', 'Feature.EnableFileIndexing', 'true', 'Boolean', 'Whether file indexing features are enabled', 0, 'SYSTEM');
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[GlobalSettings] WHERE [SettingKey] = 'Feature.EnableTestScheduling')
    INSERT INTO [dbo].[GlobalSettings] ([Category], [SettingKey], [SettingValue], [DataType], [Description], [IsUserOverridable], [CreatedBy])
    VALUES ('Feature', 'Feature.EnableTestScheduling', 'false', 'Boolean', 'Whether test scheduling features are enabled', 0, 'SYSTEM');
GO

PRINT 'GlobalSettings seed completed successfully.';
GO