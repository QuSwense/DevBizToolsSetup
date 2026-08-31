USE [ServiceHubDb];
GO

-- =========================================================================
-- Script: Safe Clean-Up of All ServiceHubDb Tables
-- Description: Disables foreign keys, clears data, resets IDENTITY counters,
--              re-enables foreign keys, and reseeds required baseline user.
-- =========================================================================

BEGIN TRANSACTION;

BEGIN TRY
    PRINT '1. Disabling all foreign key constraints...';
    EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';

    PRINT '2. Clearing all application and test data...';
    -- Execution & Validation Tables
    DELETE FROM [dbo].[TestCaseValidationRules];
    DELETE FROM [dbo].[TestCases];
    DELETE FROM [dbo].[TestSuites];
    DELETE FROM [dbo].[SoapResponseFileHistory];
    DELETE FROM [dbo].[SoapResponseEmbeddings];
    DELETE FROM [dbo].[SoapResponseFiles];
    DELETE FROM [dbo].[SoapExecutionItemRuns];
    DELETE FROM [dbo].[SoapExecutionRuns];
    DELETE FROM [dbo].[SoapExecutionGroupItems];
    DELETE FROM [dbo].[SoapExecutionGroupsPermissions];
    DELETE FROM [dbo].[SoapExecutionGroups];

    -- Files, Operations & Schema Metadata
    DELETE FROM [dbo].[SoapRequestFileHistory];
    DELETE FROM [dbo].[SoapRequestFilePermissions];
    DELETE FROM [dbo].[SoapRequestFiles];
    DELETE FROM [dbo].[SoapNamespaces];
    DELETE FROM [dbo].[SoapOperationSchemas];
    DELETE FROM [dbo].[SoapOperations];
    DELETE FROM [dbo].[SoapWsdlHistory];
    DELETE FROM [dbo].[SoapWsdlSync];
    DELETE FROM [dbo].[SoapAppPermissions];
    DELETE FROM [dbo].[SoapAppAuthentication];
    DELETE FROM [dbo].[SoapApplications];

    -- User Preferences & System Logs
    DELETE FROM [dbo].[UserSettings];
    DELETE FROM [dbo].[ConstantSettings];
    DELETE FROM [dbo].[EntityChangeHistory];
    DELETE FROM [dbo].[UserActivities];
    DELETE FROM [dbo].[Users];

    PRINT '3. Reseeding IDENTITY counters where applicable...';
    DBCC CHECKIDENT ('[dbo].[TestCaseValidationRules]', RESEED, 0);
    DBCC CHECKIDENT ('[dbo].[TestCases]', RESEED, 0);
    DBCC CHECKIDENT ('[dbo].[TestSuites]', RESEED, 0);
    DBCC CHECKIDENT ('[dbo].[SoapResponseFileHistory]', RESEED, 0);
    DBCC CHECKIDENT ('[dbo].[SoapResponseEmbeddings]', RESEED, 0);
    DBCC CHECKIDENT ('[dbo].[SoapResponseFiles]', RESEED, 0);
    DBCC CHECKIDENT ('[dbo].[SoapExecutionItemRuns]', RESEED, 0);
    DBCC CHECKIDENT ('[dbo].[SoapExecutionRuns]', RESEED, 0);
    DBCC CHECKIDENT ('[dbo].[SoapExecutionGroupItems]', RESEED, 0);
    DBCC CHECKIDENT ('[dbo].[SoapExecutionGroupsPermissions]', RESEED, 0);
    DBCC CHECKIDENT ('[dbo].[SoapExecutionGroups]', RESEED, 0);
    DBCC CHECKIDENT ('[dbo].[SoapRequestFileHistory]', RESEED, 0);
    DBCC CHECKIDENT ('[dbo].[SoapRequestFilePermissions]', RESEED, 0);
    DBCC CHECKIDENT ('[dbo].[SoapRequestFiles]', RESEED, 0);
    DBCC CHECKIDENT ('[dbo].[SoapNamespaces]', RESEED, 0);
    DBCC CHECKIDENT ('[dbo].[SoapOperationSchemas]', RESEED, 0);
    DBCC CHECKIDENT ('[dbo].[SoapOperations]', RESEED, 0);
    DBCC CHECKIDENT ('[dbo].[SoapWsdlHistory]', RESEED, 0);
    DBCC CHECKIDENT ('[dbo].[SoapWsdlSync]', RESEED, 0);
    DBCC CHECKIDENT ('[dbo].[SoapAppPermissions]', RESEED, 0);
    DBCC CHECKIDENT ('[dbo].[SoapAppAuthentication]', RESEED, 0);
    DBCC CHECKIDENT ('[dbo].[SoapApplications]', RESEED, 0);
    DBCC CHECKIDENT ('[dbo].[UserSettings]', RESEED, 0);
    DBCC CHECKIDENT ('[dbo].[ConstantSettings]', RESEED, 0);
    DBCC CHECKIDENT ('[dbo].[EntityChangeHistory]', RESEED, 0);
    DBCC CHECKIDENT ('[dbo].[UserActivities]', RESEED, 0);

    PRINT '4. Reseeding essential base system users & settings...';
    -- Seed System Admin / Test Runner Users (Required for FKs during tests)
    INSERT INTO [dbo].[Users] ([UserId], [Email], [Department], [FirstName], [LastName], [Role], [IsActive], [CreatedBy], [CreatedDate])
    VALUES 
        ('1', 'admin.system@servicehub.org', 'Core Engineering', 'System', 'Administrator', 'Developer', 1, '1', GETDATE()),
        ('TEST_RUNNER', 'test.runner@servicehub.org', 'Quality Assurance', 'Automation', 'Runner', 'Test Engineer', 1, '1', GETDATE());

    -- Seed Default Constant Settings
    INSERT INTO [dbo].[ConstantSettings] ([SettingKey], [SettingValue], [Description], [IsActive])
    VALUES ('RequestFileDiffCount', '5', 'Number of diff payload increments retained in history before forcing full base file snapshot', 1);

    PRINT '5. Re-enabling and validating all foreign key constraints...';
    EXEC sp_MSforeachtable 'ALTER TABLE ? WITH CHECK CHECK CONSTRAINT ALL';

    COMMIT TRANSACTION;
    PRINT ' SUCCESS: Database cleared and default seed data restored successfully.';

END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    
    -- Ensure FKs get re-enabled if error occurs during transaction
    EXEC sp_MSforeachtable 'ALTER TABLE ? WITH CHECK CHECK CONSTRAINT ALL';
    
    PRINT ' ERROR: Clean-up script failed!';
    PRINT ERROR_MESSAGE();
END CATCH;
GO