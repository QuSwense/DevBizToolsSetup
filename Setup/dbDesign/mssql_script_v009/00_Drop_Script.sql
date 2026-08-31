-- ==========================================
-- 00: Cleanup / Teardown Script
-- Drops foreign keys, tables, function,
-- and optionally the database in reverse dependency order
-- Based on:
-- 01_Core_and_User_Management.sql
-- 02_SOAP_and_REST_Service_Metadata.sql
-- 03_Rule_Contexts.sql
-- 04_Test_Suites_and_Execution_Groups.sql
-- ==========================================

USE [OrbitTool];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO


-- ==========================================
-- 1. Drop Foreign Key Constraints
--    Drop all FKs before dropping tables
-- ==========================================


-- ------------------------------------------
-- 04: Test Suites / Test Cases / Audits
-- ------------------------------------------

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceTestExecutionAuditTestSuitLinks_ServiceTestExecutionAudits_ServiceTestExecutionAuditId')
    ALTER TABLE dbo.[ServiceTestExecutionAuditTestSuitLinks]
        DROP CONSTRAINT FK_ServiceTestExecutionAuditTestSuitLinks_ServiceTestExecutionAudits_ServiceTestExecutionAuditId;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceTestExecutionAuditTestSuitLinks_ServiceTestCases_ServiceTestCaseId')
    ALTER TABLE dbo.[ServiceTestExecutionAuditTestSuitLinks]
        DROP CONSTRAINT FK_ServiceTestExecutionAuditTestSuitLinks_ServiceTestCases_ServiceTestCaseId;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceTestExecutionAuditTestSuitLinks_ServiceResponseFiles_ServiceResponseFileId')
    ALTER TABLE dbo.[ServiceTestExecutionAuditTestSuitLinks]
        DROP CONSTRAINT FK_ServiceTestExecutionAuditTestSuitLinks_ServiceResponseFiles_ServiceResponseFileId;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceTestExecutionAudits_ServiceTestSuites_ServiceTestSuiteId')
    ALTER TABLE dbo.[ServiceTestExecutionAudits]
        DROP CONSTRAINT FK_ServiceTestExecutionAudits_ServiceTestSuites_ServiceTestSuiteId;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceTestExecutionAudits_Users_ExecutedBy')
    ALTER TABLE dbo.[ServiceTestExecutionAudits]
        DROP CONSTRAINT FK_ServiceTestExecutionAudits_Users_ExecutedBy;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceTestSuitTestCaseLinks_ServiceTestSuites_ServiceTestSuiteId')
    ALTER TABLE dbo.[ServiceTestSuitTestCaseLinks]
        DROP CONSTRAINT FK_ServiceTestSuitTestCaseLinks_ServiceTestSuites_ServiceTestSuiteId;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceTestSuitTestCaseLinks_ServiceTestCases_ServiceTestCaseId')
    ALTER TABLE dbo.[ServiceTestSuitTestCaseLinks]
        DROP CONSTRAINT FK_ServiceTestSuitTestCaseLinks_ServiceTestCases_ServiceTestCaseId;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceTestSuitTestCaseLinks_Users_CreatedBy')
    ALTER TABLE dbo.[ServiceTestSuitTestCaseLinks]
        DROP CONSTRAINT FK_ServiceTestSuitTestCaseLinks_Users_CreatedBy;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceTestCaseRuleSetLinks_ServiceTestCases_ServiceTestCaseId')
    ALTER TABLE dbo.[ServiceTestCaseRuleSetLinks]
        DROP CONSTRAINT FK_ServiceTestCaseRuleSetLinks_ServiceTestCases_ServiceTestCaseId;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceTestCaseRuleSetLinks_RuleSets_RuleSetId')
    ALTER TABLE dbo.[ServiceTestCaseRuleSetLinks]
        DROP CONSTRAINT FK_ServiceTestCaseRuleSetLinks_RuleSets_RuleSetId;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceTestCaseRuleSetLinks_Users_CreatedBy')
    ALTER TABLE dbo.[ServiceTestCaseRuleSetLinks]
        DROP CONSTRAINT FK_ServiceTestCaseRuleSetLinks_Users_CreatedBy;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceTestCases_TestSuites_TestSuiteId')
    ALTER TABLE dbo.[ServiceTestCases]
        DROP CONSTRAINT FK_ServiceTestCases_TestSuites_TestSuiteId;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceTestCases_Users_CreatedBy')
    ALTER TABLE dbo.[ServiceTestCases]
        DROP CONSTRAINT FK_ServiceTestCases_Users_CreatedBy;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceTestCases_Users_LastUpdatedBy')
    ALTER TABLE dbo.[ServiceTestCases]
        DROP CONSTRAINT FK_ServiceTestCases_Users_LastUpdatedBy;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceTestSuites_ServiceApplications_ServiceApplicationId')
    ALTER TABLE dbo.[ServiceTestSuites]
        DROP CONSTRAINT FK_ServiceTestSuites_ServiceApplications_ServiceApplicationId;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceTestSuites_Users_CreatedBy')
    ALTER TABLE dbo.[ServiceTestSuites]
        DROP CONSTRAINT FK_ServiceTestSuites_Users_CreatedBy;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceTestSuites_Users_LastUpdatedBy')
    ALTER TABLE dbo.[ServiceTestSuites]
        DROP CONSTRAINT FK_ServiceTestSuites_Users_LastUpdatedBy;
GO


-- ------------------------------------------
-- 03: Rule Contexts
-- ------------------------------------------

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_RuleExecutionLogs_RuleSets')
    ALTER TABLE dbo.[RuleExecutionLogs]
        DROP CONSTRAINT FK_RuleExecutionLogs_RuleSets;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_RuleExecutionLogs_Users_ExecutedBy')
    ALTER TABLE dbo.[RuleExecutionLogs]
        DROP CONSTRAINT FK_RuleExecutionLogs_Users_ExecutedBy;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_RuleSetContextObjectLinks_RuleSets')
    ALTER TABLE dbo.[RuleSetContextObjectLinks]
        DROP CONSTRAINT FK_RuleSetContextObjectLinks_RuleSets;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_RuleSetContextObjectLinks_RuleContextObjects')
    ALTER TABLE dbo.[RuleSetContextObjectLinks]
        DROP CONSTRAINT FK_RuleSetContextObjectLinks_RuleContextObjects;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_RuleSets_RuleContextObjects')
    ALTER TABLE dbo.[RuleSets]
        DROP CONSTRAINT FK_RuleSets_RuleContextObjects;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_RuleSets_Users_CreatedBy')
    ALTER TABLE dbo.[RuleSets]
        DROP CONSTRAINT FK_RuleSets_Users_CreatedBy;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_RuleSets_Users_LastUpdatedBy')
    ALTER TABLE dbo.[RuleSets]
        DROP CONSTRAINT FK_RuleSets_Users_LastUpdatedBy;
GO


-- ------------------------------------------
-- 02: SOAP / REST Service Metadata
-- ------------------------------------------

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_DirectExecutionAuditResponseFileLinks_DirectExecutionAudit_DirectExecutionAuditId')
    ALTER TABLE dbo.[DirectExecutionAuditResponseFileLinks]
        DROP CONSTRAINT FK_DirectExecutionAuditResponseFileLinks_DirectExecutionAudit_DirectExecutionAuditId;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_DirectExecutionAuditResponseFileLinks_ServiceRequestFiles_ServiceRequestFileId')
    ALTER TABLE dbo.[DirectExecutionAuditResponseFileLinks]
        DROP CONSTRAINT FK_DirectExecutionAuditResponseFileLinks_ServiceRequestFiles_ServiceRequestFileId;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_DirectExecutionAuditResponseFileLinks_ServiceResponseFiles_ServiceResponseFileId')
    ALTER TABLE dbo.[DirectExecutionAuditResponseFileLinks]
        DROP CONSTRAINT FK_DirectExecutionAuditResponseFileLinks_ServiceResponseFiles_ServiceResponseFileId;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_DirectExecutionAudit_Users_ExecutedBy')
    ALTER TABLE dbo.[DirectExecutionAudit]
        DROP CONSTRAINT FK_DirectExecutionAudit_Users_ExecutedBy;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_SoapNamespaces_ServiceOperationSchemas_ServiceOperationSchemaId')
    ALTER TABLE dbo.[SoapNamespaces]
        DROP CONSTRAINT FK_SoapNamespaces_ServiceOperationSchemas_ServiceOperationSchemaId;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceAppPermissions_ServiceApplications_ServiceApplicationId')
    ALTER TABLE dbo.[ServiceAppPermissions]
        DROP CONSTRAINT FK_ServiceAppPermissions_ServiceApplications_ServiceApplicationId;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceAppPermissions_Users_SharedWithUserId')
    ALTER TABLE dbo.[ServiceAppPermissions]
        DROP CONSTRAINT FK_ServiceAppPermissions_Users_SharedWithUserId;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceAppPermissions_Users_GrantedBy')
    ALTER TABLE dbo.[ServiceAppPermissions]
        DROP CONSTRAINT FK_ServiceAppPermissions_Users_GrantedBy;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceOperationSchemas_ServiceDefinitionSync_DefinitionSyncId')
    ALTER TABLE dbo.[ServiceOperationSchemas]
        DROP CONSTRAINT FK_ServiceOperationSchemas_ServiceDefinitionSync_DefinitionSyncId;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceOperationSchemas_ServiceOperations_OperationId')
    ALTER TABLE dbo.[ServiceOperationSchemas]
        DROP CONSTRAINT FK_ServiceOperationSchemas_ServiceOperations_OperationId;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceResponseFileEmbeddings_ServiceResponseFiles_ServiceResponseFileId')
    ALTER TABLE dbo.[ServiceResponseFileEmbeddings]
        DROP CONSTRAINT FK_ServiceResponseFileEmbeddings_ServiceResponseFiles_ServiceResponseFileId;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceRequestFileEmbeddings_ServiceRequestFiles')
    ALTER TABLE dbo.[ServiceRequestFileEmbeddings]
        DROP CONSTRAINT FK_ServiceRequestFileEmbeddings_ServiceRequestFiles;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceRequestFileEmbeddings_ServiceRequestFileHistorys')
    ALTER TABLE dbo.[ServiceRequestFileEmbeddings]
        DROP CONSTRAINT FK_ServiceRequestFileEmbeddings_ServiceRequestFileHistorys;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceRequestFileHistorys_ServiceRequestFiles_ServiceRequestFileId')
    ALTER TABLE dbo.[ServiceRequestFileHistorys]
        DROP CONSTRAINT FK_ServiceRequestFileHistorys_ServiceRequestFiles_ServiceRequestFileId;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceRequestFileHistorys_Users_CreatedBy')
    ALTER TABLE dbo.[ServiceRequestFileHistorys]
        DROP CONSTRAINT FK_ServiceRequestFileHistorys_Users_CreatedBy;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceRequestFileHistorys_Users_LastUpdatedBy')
    ALTER TABLE dbo.[ServiceRequestFileHistorys]
        DROP CONSTRAINT FK_ServiceRequestFileHistorys_Users_LastUpdatedBy;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceRequestFiles_ServiceOperations_OperationId')
    ALTER TABLE dbo.[ServiceRequestFiles]
        DROP CONSTRAINT FK_ServiceRequestFiles_ServiceOperations_OperationId;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceRequestFiles_Users_CreatedBy')
    ALTER TABLE dbo.[ServiceRequestFiles]
        DROP CONSTRAINT FK_ServiceRequestFiles_Users_CreatedBy;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceRequestFiles_Users_LastUpdatedBy')
    ALTER TABLE dbo.[ServiceRequestFiles]
        DROP CONSTRAINT FK_ServiceRequestFiles_Users_LastUpdatedBy;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceOperations_ServiceApplications_ServiceApplicationId')
    ALTER TABLE dbo.[ServiceOperations]
        DROP CONSTRAINT FK_ServiceOperations_ServiceApplications_ServiceApplicationId;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceOperations_Users_CreatedBy')
    ALTER TABLE dbo.[ServiceOperations]
        DROP CONSTRAINT FK_ServiceOperations_Users_CreatedBy;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceOperations_Users_LastUpdatedBy')
    ALTER TABLE dbo.[ServiceOperations]
        DROP CONSTRAINT FK_ServiceOperations_Users_LastUpdatedBy;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceDefinitionSyncHistorys_ServiceApplications_ServiceApplicationId')
    ALTER TABLE dbo.[ServiceDefinitionSyncHistorys]
        DROP CONSTRAINT FK_ServiceDefinitionSyncHistorys_ServiceApplications_ServiceApplicationId;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceDefinitionSyncHistorys_ServiceDefinitionSyncs_ServiceDefinitionSyncId')
    ALTER TABLE dbo.[ServiceDefinitionSyncHistorys]
        DROP CONSTRAINT FK_ServiceDefinitionSyncHistorys_ServiceDefinitionSyncs_ServiceDefinitionSyncId;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceDefinitionSyncHistorys_Users_SyncedBy')
    ALTER TABLE dbo.[ServiceDefinitionSyncHistorys]
        DROP CONSTRAINT FK_ServiceDefinitionSyncHistorys_Users_SyncedBy;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceDefinitionSyncHistorys_Users_ChangedBy')
    ALTER TABLE dbo.[ServiceDefinitionSyncHistorys]
        DROP CONSTRAINT FK_ServiceDefinitionSyncHistorys_Users_ChangedBy;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceDefinitionSyncs_ServiceApplications_ServiceApplicationId')
    ALTER TABLE dbo.[ServiceDefinitionSyncs]
        DROP CONSTRAINT FK_ServiceDefinitionSyncs_ServiceApplications_ServiceApplicationId;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceDefinitionSyncs_Users_SyncedBy')
    ALTER TABLE dbo.[ServiceDefinitionSyncs]
        DROP CONSTRAINT FK_ServiceDefinitionSyncs_Users_SyncedBy;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceApplications_ServiceAppAuthentications_AuthenticationId')
    ALTER TABLE dbo.[ServiceApplications]
        DROP CONSTRAINT FK_ServiceApplications_ServiceAppAuthentications_AuthenticationId;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceApplications_Users_CreatedBy')
    ALTER TABLE dbo.[ServiceApplications]
        DROP CONSTRAINT FK_ServiceApplications_Users_CreatedBy;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceApplications_Users_LastUpdatedBy')
    ALTER TABLE dbo.[ServiceApplications]
        DROP CONSTRAINT FK_ServiceApplications_Users_LastUpdatedBy;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceAppAuthentications_Users_CreatedBy')
    ALTER TABLE dbo.[ServiceAppAuthentications]
        DROP CONSTRAINT FK_ServiceAppAuthentications_Users_CreatedBy;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_ServiceAppAuthentications_Users_LastUpdatedBy')
    ALTER TABLE dbo.[ServiceAppAuthentications]
        DROP CONSTRAINT FK_ServiceAppAuthentications_Users_LastUpdatedBy;
GO


-- ------------------------------------------
-- 01: Core / Users / Settings
-- ------------------------------------------

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_UserSettings_GlobalSettings_GlobalSettingId')
    ALTER TABLE dbo.[UserSettings]
        DROP CONSTRAINT FK_UserSettings_GlobalSettings_GlobalSettingId;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_UserSettings_Users_UserId')
    ALTER TABLE dbo.[UserSettings]
        DROP CONSTRAINT FK_UserSettings_Users_UserId;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_GlobalSettings_Users_LastUpdatedBy')
    ALTER TABLE dbo.[GlobalSettings]
        DROP CONSTRAINT FK_GlobalSettings_Users_LastUpdatedBy;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_UserActivities_Users_UserId')
    ALTER TABLE dbo.[UserActivities]
        DROP CONSTRAINT FK_UserActivities_Users_UserId;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Users_LastUpdatedBy_Users')
    ALTER TABLE dbo.[Users]
        DROP CONSTRAINT FK_Users_LastUpdatedBy_Users;
GO

IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Users_CreatedBy_Users')
    ALTER TABLE dbo.[Users]
        DROP CONSTRAINT FK_Users_CreatedBy_Users;
GO


-- ==========================================
-- 2. Drop Tables
--    Child tables first, then parent tables
-- ==========================================


-- ------------------------------------------
-- 04: Test Suites / Test Cases / Audits
-- ------------------------------------------

IF OBJECT_ID(N'dbo.ServiceTestExecutionAuditTestSuitLinks', N'U') IS NOT NULL
    DROP TABLE dbo.[ServiceTestExecutionAuditTestSuitLinks];
GO

IF OBJECT_ID(N'dbo.ServiceTestCaseRuleSetLinks', N'U') IS NOT NULL
    DROP TABLE dbo.[ServiceTestCaseRuleSetLinks];
GO

IF OBJECT_ID(N'dbo.ServiceTestSuitTestCaseLinks', N'U') IS NOT NULL
    DROP TABLE dbo.[ServiceTestSuitTestCaseLinks];
GO

IF OBJECT_ID(N'dbo.ServiceTestExecutionAudits', N'U') IS NOT NULL
    DROP TABLE dbo.[ServiceTestExecutionAudits];
GO

IF OBJECT_ID(N'dbo.ServiceTestCases', N'U') IS NOT NULL
    DROP TABLE dbo.[ServiceTestCases];
GO

IF OBJECT_ID(N'dbo.ServiceTestSuites', N'U') IS NOT NULL
    DROP TABLE dbo.[ServiceTestSuites];
GO


-- ------------------------------------------
-- 03: Rule Contexts
-- ------------------------------------------

IF OBJECT_ID(N'dbo.RuleExecutionLogs', N'U') IS NOT NULL
    DROP TABLE dbo.[RuleExecutionLogs];
GO

IF OBJECT_ID(N'dbo.RuleSetContextObjectLinks', N'U') IS NOT NULL
    DROP TABLE dbo.[RuleSetContextObjectLinks];
GO

IF OBJECT_ID(N'dbo.RuleSets', N'U') IS NOT NULL
    DROP TABLE dbo.[RuleSets];
GO

IF OBJECT_ID(N'dbo.RuleContextObjects', N'U') IS NOT NULL
    DROP TABLE dbo.[RuleContextObjects];
GO


-- ------------------------------------------
-- 02: SOAP / REST Service Metadata
-- ------------------------------------------

IF OBJECT_ID(N'dbo.DirectExecutionAuditResponseFileLinks', N'U') IS NOT NULL
    DROP TABLE dbo.[DirectExecutionAuditResponseFileLinks];
GO

IF OBJECT_ID(N'dbo.DirectExecutionAudit', N'U') IS NOT NULL
    DROP TABLE dbo.[DirectExecutionAudit];
GO

IF OBJECT_ID(N'dbo.ServiceAppPermissions', N'U') IS NOT NULL
    DROP TABLE dbo.[ServiceAppPermissions];
GO

IF OBJECT_ID(N'dbo.SoapNamespaces', N'U') IS NOT NULL
    DROP TABLE dbo.[SoapNamespaces];
GO

IF OBJECT_ID(N'dbo.ServiceOperationSchemas', N'U') IS NOT NULL
    DROP TABLE dbo.[ServiceOperationSchemas];
GO

IF OBJECT_ID(N'dbo.ServiceResponseFileEmbeddings', N'U') IS NOT NULL
    DROP TABLE dbo.[ServiceResponseFileEmbeddings];
GO

IF OBJECT_ID(N'dbo.ServiceRequestFileEmbeddings', N'U') IS NOT NULL
    DROP TABLE dbo.[ServiceRequestFileEmbeddings];
GO

IF OBJECT_ID(N'dbo.ServiceRequestFileHistorys', N'U') IS NOT NULL
    DROP TABLE dbo.[ServiceRequestFileHistorys];
GO

IF OBJECT_ID(N'dbo.ServiceRequestFiles', N'U') IS NOT NULL
    DROP TABLE dbo.[ServiceRequestFiles];
GO

IF OBJECT_ID(N'dbo.ServiceResponseFiles', N'U') IS NOT NULL
    DROP TABLE dbo.[ServiceResponseFiles];
GO

IF OBJECT_ID(N'dbo.ServiceOperations', N'U') IS NOT NULL
    DROP TABLE dbo.[ServiceOperations];
GO

IF OBJECT_ID(N'dbo.ServiceDefinitionSyncHistorys', N'U') IS NOT NULL
    DROP TABLE dbo.[ServiceDefinitionSyncHistorys];
GO

IF OBJECT_ID(N'dbo.ServiceDefinitionSyncs', N'U') IS NOT NULL
    DROP TABLE dbo.[ServiceDefinitionSyncs];
GO

IF OBJECT_ID(N'dbo.ServiceApplications', N'U') IS NOT NULL
    DROP TABLE dbo.[ServiceApplications];
GO

IF OBJECT_ID(N'dbo.ServiceAppAuthentications', N'U') IS NOT NULL
    DROP TABLE dbo.[ServiceAppAuthentications];
GO


-- ------------------------------------------
-- 01: Core / Users / Settings
-- ------------------------------------------

IF OBJECT_ID(N'dbo.UserSettings', N'U') IS NOT NULL
    DROP TABLE dbo.[UserSettings];
GO

IF OBJECT_ID(N'dbo.GlobalSettings', N'U') IS NOT NULL
    DROP TABLE dbo.[GlobalSettings];
GO

IF OBJECT_ID(N'dbo.UserActivities', N'U') IS NOT NULL
    DROP TABLE dbo.[UserActivities];
GO

IF OBJECT_ID(N'dbo.Users', N'U') IS NOT NULL
    DROP TABLE dbo.[Users];
GO


-- ==========================================
-- 3. Drop Function
-- ==========================================

IF OBJECT_ID(N'dbo.fn_CalculateVersion', N'FN') IS NOT NULL
    DROP FUNCTION dbo.[fn_CalculateVersion];
GO


-- ==========================================
-- 4. Database Drop (Optional)
-- ==========================================
/*
USE [master];
GO

IF EXISTS (
    SELECT 1
    FROM [sys].[databases]
    WHERE [name] = N'ServiceHubDb'
)
BEGIN
    ALTER DATABASE [ServiceHubDb]
        SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    DROP DATABASE [ServiceHubDb];
END
GO
*/