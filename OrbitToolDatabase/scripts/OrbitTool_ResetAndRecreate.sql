/*
    OrbitTool database reset and schema recreation script.
    Run from OrbitToolDatabase/scripts with SQLCMD while connected to the OrbitTool server.
*/

:on error exit
:setvar DatabaseName "OrbitTool"

USE [$(DatabaseName)];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* Drop every existing foreign key before dropping tables. */
DECLARE @ConstraintSchema sysname;
DECLARE @ParentTable sysname;
DECLARE @ConstraintName sysname;
DECLARE @DropConstraintSql nvarchar(max);

DECLARE ForeignKeyCursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT
        SCHEMA_NAME(parent_object.schema_id),
        parent_object.name,
        foreign_key.name
    FROM sys.foreign_keys AS foreign_key
    INNER JOIN sys.tables AS parent_object
        ON parent_object.object_id = foreign_key.parent_object_id
    ORDER BY
        parent_object.schema_id,
        parent_object.name,
        foreign_key.name;

OPEN ForeignKeyCursor;
FETCH NEXT FROM ForeignKeyCursor
    INTO @ConstraintSchema, @ParentTable, @ConstraintName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @DropConstraintSql =
        N'IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N''' +
        REPLACE(@ConstraintSchema + N'.' + @ConstraintName, '''', '''''') +
        N''')) ALTER TABLE ' + QUOTENAME(@ConstraintSchema) + N'.' +
        QUOTENAME(@ParentTable) + N' DROP CONSTRAINT ' + QUOTENAME(@ConstraintName) + N';';

    EXEC sys.sp_executesql @DropConstraintSql;

    FETCH NEXT FROM ForeignKeyCursor
        INTO @ConstraintSchema, @ParentTable, @ConstraintName;
END;

CLOSE ForeignKeyCursor;
DEALLOCATE ForeignKeyCursor;
GO

/* Drop tables from most-dependent to least-dependent. */
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.DirectExecutionAuditResponseFileLinks')) DROP TABLE [dbo].[DirectExecutionAuditResponseFileLinks];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceTestExecutionAuditTestSuitLinks')) DROP TABLE [dbo].[ServiceTestExecutionAuditTestSuitLinks];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceTestCaseRuleSetLinks')) DROP TABLE [dbo].[ServiceTestCaseRuleSetLinks];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceTestSuitTestCaseLinks')) DROP TABLE [dbo].[ServiceTestSuitTestCaseLinks];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceRequestFileEmbeddings')) DROP TABLE [dbo].[ServiceRequestFileEmbeddings];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceResponseFileEmbeddings')) DROP TABLE [dbo].[ServiceResponseFileEmbeddings];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.SoapNamespaces')) DROP TABLE [dbo].[SoapNamespaces];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceOperationSchemas')) DROP TABLE [dbo].[ServiceOperationSchemas];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceDefinitionSyncHistorys')) DROP TABLE [dbo].[ServiceDefinitionSyncHistorys];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceRequestFileHistorys')) DROP TABLE [dbo].[ServiceRequestFileHistorys];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceRequestFiles')) DROP TABLE [dbo].[ServiceRequestFiles];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceTestExecutionAudits')) DROP TABLE [dbo].[ServiceTestExecutionAudits];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceTestSuites')) DROP TABLE [dbo].[ServiceTestSuites];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceTestCases')) DROP TABLE [dbo].[ServiceTestCases];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceOperations')) DROP TABLE [dbo].[ServiceOperations];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceDefinitionSyncs')) DROP TABLE [dbo].[ServiceDefinitionSyncs];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceAppPermissions')) DROP TABLE [dbo].[ServiceAppPermissions];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceApplications')) DROP TABLE [dbo].[ServiceApplications];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceAppAuthentications')) DROP TABLE [dbo].[ServiceAppAuthentications];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.DirectExecutionAudit')) DROP TABLE [dbo].[DirectExecutionAudit];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.RuleExecutionLogs')) DROP TABLE [dbo].[RuleExecutionLogs];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.RuleSetContextObjectLinks')) DROP TABLE [dbo].[RuleSetContextObjectLinks];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.RuleSets')) DROP TABLE [dbo].[RuleSets];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.UserSettings')) DROP TABLE [dbo].[UserSettings];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.UserActivities')) DROP TABLE [dbo].[UserActivities];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.GlobalSettings')) DROP TABLE [dbo].[GlobalSettings];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.RuleContextObjects')) DROP TABLE [dbo].[RuleContextObjects];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceResponseFiles')) DROP TABLE [dbo].[ServiceResponseFiles];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.Users')) DROP TABLE [dbo].[Users];
GO

/* Drop functions after tables, then recreate the function before dependent tables. */
IF EXISTS (
    SELECT 1
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'dbo.fn_CalculateVersion')
      AND type IN ('FN', 'IF', 'TF', 'FS', 'FT')
)
    DROP FUNCTION [dbo].[fn_CalculateVersion];
GO

:r ../dbo/Functions/fn_CalculateVersion.sql
GO

/* Recreate tables from project source, honoring foreign-key dependencies. */
:r ../dbo/Tables/Users.sql
GO
:r ../dbo/Tables/RuleContextObjects.sql
GO
:r ../dbo/Tables/GlobalSettings.sql
GO
:r ../dbo/Tables/UserActivities.sql
GO
:r ../dbo/Tables/UserSettings.sql
GO
:r ../dbo/Tables/RuleSets.sql
GO
:r ../dbo/Tables/RuleSetContextObjectLinks.sql
GO
:r ../dbo/Tables/RuleExecutionLogs.sql
GO
:r ../dbo/Tables/ServiceAppAuthentications.sql
GO
:r ../dbo/Tables/ServiceApplications.sql
GO
:r ../dbo/Tables/ServiceAppPermissions.sql
GO
:r ../dbo/Tables/ServiceDefinitionSyncs.sql
GO
:r ../dbo/Tables/ServiceDefinitionSyncHistorys.sql
GO
:r ../dbo/Tables/ServiceOperations.sql
GO
:r ../dbo/Tables/ServiceOperationSchemas.sql
GO
:r ../dbo/Tables/SoapNamespaces.sql
GO
:r ../dbo/Tables/ServiceRequestFiles.sql
GO
:r ../dbo/Tables/ServiceRequestFileHistorys.sql
GO
:r ../dbo/Tables/ServiceRequestFileEmbeddings.sql
GO
:r ../dbo/Tables/ServiceResponseFiles.sql
GO
:r ../dbo/Tables/ServiceResponseFileEmbeddings.sql
GO
:r ../dbo/Tables/ServiceTestCases.sql
GO
:r ../dbo/Tables/ServiceTestSuites.sql
GO
:r ../dbo/Tables/ServiceTestCaseRuleSetLinks.sql
GO
:r ../dbo/Tables/ServiceTestSuitTestCaseLinks.sql
GO
:r ../dbo/Tables/ServiceTestExecutionAudits.sql
GO
:r ../dbo/Tables/ServiceTestExecutionAuditTestSuitLinks.sql
GO
:r ../dbo/Tables/DirectExecutionAudit.sql
GO
:r ../dbo/Tables/DirectExecutionAuditResponseFileLinks.sql
GO

/* Recreate project triggers after all referenced tables exist. */
:r ../dbo/Triggers/trg_ServiceAppAuthentications_AutoUpdate.sql
GO
:r ../dbo/Triggers/trg_ServiceApplications_AutoUpdate.sql
GO
:r ../dbo/Triggers/trg_ServiceDefinitionSyncs_AutoUpdate.sql
GO
:r ../dbo/Triggers/trg_ServiceOperations_AutoUpdate.sql
GO
:r ../dbo/Triggers/trg_ServiceRequestFiles_Audit.sql
GO

/* Apply documentation after all tables and foreign keys are available. */
:r ApplyColumnDescriptions.sql
GO

PRINT N'OrbitTool schema reset and recreation completed successfully.';
GO
