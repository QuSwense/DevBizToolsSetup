/*
    OrbitTool database reset and schema recreation script.
    Run from OrbitToolDatabase/scripts with SQLCMD while connected to the OrbitTool server.

    This script resets and recreates the FULL schema from the SQL project source in ../dbo.
    It drops every view, stored procedure, foreign key, table (most-dependent first), the
    IndexingCatalog full-text catalog, and the fn_CalculateVersion function, then recreates
    the function, all tables (honoring foreign-key dependencies), all views, all stored
    procedures, and applies column descriptions.

    To keep the previous tables-only behavior, comment out the two marked sections below
    ("Drop views and stored procedures" and "Recreate views and stored procedures").
*/

:on error exit
:setvar DatabaseName "OrbitTool"

USE [$(DatabaseName)];
GO

/* ANSI_NULLS and QUOTED_IDENTIFIER must be ON for filtered indexes, full-text
   indexes, and indexed views (sqlcmd defaults them to OFF). */
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
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

/* =====================================================================
   Drop views and stored procedures (recreated later from ../dbo).
   Comment out this section to keep the tables-only reset behavior.
   ===================================================================== */
DECLARE @ViewName sysname;
DECLARE @DropViewSql nvarchar(max);

DECLARE ViewCursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT QUOTENAME([name])
    FROM sys.views
    WHERE SCHEMA_NAME([schema_id]) = N'dbo'
    ORDER BY [name];

OPEN ViewCursor;
FETCH NEXT FROM ViewCursor INTO @ViewName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @DropViewSql = N'DROP VIEW ' + @ViewName + N';';
    EXEC sys.sp_executesql @DropViewSql;

    FETCH NEXT FROM ViewCursor INTO @ViewName;
END;

CLOSE ViewCursor;
DEALLOCATE ViewCursor;
GO

DECLARE @ProcName sysname;
DECLARE @DropProcSql nvarchar(max);

DECLARE ProcCursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT QUOTENAME([name])
    FROM sys.procedures
    WHERE SCHEMA_NAME([schema_id]) = N'dbo'
    ORDER BY [name];

OPEN ProcCursor;
FETCH NEXT FROM ProcCursor INTO @ProcName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @DropProcSql = N'DROP PROCEDURE ' + @ProcName + N';';
    EXEC sys.sp_executesql @DropProcSql;

    FETCH NEXT FROM ProcCursor INTO @ProcName;
END;

CLOSE ProcCursor;
DEALLOCATE ProcCursor;
GO

/* Drop tables from most-dependent to least-dependent. */
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.IndexingPdfFileElementSearch')) DROP TABLE [dbo].[IndexingPdfFileElementSearch];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.IndexingPdfFileElementMappings')) DROP TABLE [dbo].[IndexingPdfFileElementMappings];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.IndexingPdfFileElements')) DROP TABLE [dbo].[IndexingPdfFileElements];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.IndexingJsonFileElementSearch')) DROP TABLE [dbo].[IndexingJsonFileElementSearch];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.IndexingJsonFileElementMappings')) DROP TABLE [dbo].[IndexingJsonFileElementMappings];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.IndexingJsonFileElements')) DROP TABLE [dbo].[IndexingJsonFileElements];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.IndexingXmlFileElementSearch')) DROP TABLE [dbo].[IndexingXmlFileElementSearch];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.IndexingXmlFileElementMappings')) DROP TABLE [dbo].[IndexingXmlFileElementMappings];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.IndexingXmlFileElements')) DROP TABLE [dbo].[IndexingXmlFileElements];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.DirectExecutionAuditResponseFileLinks')) DROP TABLE [dbo].[DirectExecutionAuditResponseFileLinks];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.DirectExecutionAudit')) DROP TABLE [dbo].[DirectExecutionAudit];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceTestSuiteExecutionAuditTestCaseLinks')) DROP TABLE [dbo].[ServiceTestSuiteExecutionAuditTestCaseLinks];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceTestSuiteExecutionAudits')) DROP TABLE [dbo].[ServiceTestSuiteExecutionAudits];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceTestSuiteTestCaseLinks')) DROP TABLE [dbo].[ServiceTestSuiteTestCaseLinks];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceTestCaseRuleSetLinks')) DROP TABLE [dbo].[ServiceTestCaseRuleSetLinks];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceTestSuitesPermissions')) DROP TABLE [dbo].[ServiceTestSuitesPermissions];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceTestSuites')) DROP TABLE [dbo].[ServiceTestSuites];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceTestCasesPermissions')) DROP TABLE [dbo].[ServiceTestCasesPermissions];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceTestCases')) DROP TABLE [dbo].[ServiceTestCases];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceResponseIndexingStatus')) DROP TABLE [dbo].[ServiceResponseIndexingStatus];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceResponseFileEmbeddings')) DROP TABLE [dbo].[ServiceResponseFileEmbeddings];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceResponseFiles')) DROP TABLE [dbo].[ServiceResponseFiles];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceRequestIndexingStatus')) DROP TABLE [dbo].[ServiceRequestIndexingStatus];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceRequestFileEmbeddings')) DROP TABLE [dbo].[ServiceRequestFileEmbeddings];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceRequestFilesPermissions')) DROP TABLE [dbo].[ServiceRequestFilesPermissions];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceRequestFiles')) DROP TABLE [dbo].[ServiceRequestFiles];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.BinaryEmbeddingsStore')) DROP TABLE [dbo].[BinaryEmbeddingsStore];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.SoapNamespaces')) DROP TABLE [dbo].[SoapNamespaces];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceOperationSchemas')) DROP TABLE [dbo].[ServiceOperationSchemas];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceOperations')) DROP TABLE [dbo].[ServiceOperations];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceDefinitionSyncs')) DROP TABLE [dbo].[ServiceDefinitionSyncs];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceAppPermissions')) DROP TABLE [dbo].[ServiceAppPermissions];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceApplications')) DROP TABLE [dbo].[ServiceApplications];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceAppAuthentications')) DROP TABLE [dbo].[ServiceAppAuthentications];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.RuleExecutionLogs')) DROP TABLE [dbo].[RuleExecutionLogs];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.RuleSetContextObjectLinks')) DROP TABLE [dbo].[RuleSetContextObjectLinks];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.RuleSetsPermissions')) DROP TABLE [dbo].[RuleSetsPermissions];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.RuleSets')) DROP TABLE [dbo].[RuleSets];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.UserSettings')) DROP TABLE [dbo].[UserSettings];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.UserActivities')) DROP TABLE [dbo].[UserActivities];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.UserPermissions')) DROP TABLE [dbo].[UserPermissions];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.RolePermissions')) DROP TABLE [dbo].[RolePermissions];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.PermissionToUIPageMapping')) DROP TABLE [dbo].[PermissionToUIPageMapping];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.UIActions')) DROP TABLE [dbo].[UIActions];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.UIPages')) DROP TABLE [dbo].[UIPages];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ResourcePermissions')) DROP TABLE [dbo].[ResourcePermissions];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.GlobalSettings')) DROP TABLE [dbo].[GlobalSettings];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.RuleContextObjects')) DROP TABLE [dbo].[RuleContextObjects];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.UserRoles')) DROP TABLE [dbo].[UserRoles];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.Roles')) DROP TABLE [dbo].[Roles];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.Users')) DROP TABLE [dbo].[Users];
GO

/* Drop the full-text catalog if it still exists (legacy cleanup). */
IF EXISTS (SELECT 1 FROM sys.fulltext_catalogs WHERE name = N'IndexingCatalog')
    DROP FULLTEXT CATALOG [IndexingCatalog];
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

/* Recreate tables from project source, honoring foreign-key dependencies.
   Users and Roles no longer have a circular foreign-key relationship: the
   Users.RoleId column and its FK were removed and replaced by the UserRoles
   junction table (dbo/Tables/UserRoles.sql), so every table can be created
   directly from its project source file with no inline DDL or deferred ALTER. */
:r ../dbo/Tables/Users.sql
GO

/* Seed the SYSTEM user so the Roles seed (and other seeds) that set
   CreatedBy = N'SYSTEM' satisfy the FK_*_Users_CreatedBy constraints. */
/* Matches Seeds/UsersSeed.sql (SYSTEM bootstrap row; CreatedBy = NULL there,
   N'SYSTEM' here because the FK_Users_Users_CreatedBy constraint needs the row
   itself to exist before other rows can reference it). */
IF NOT EXISTS (SELECT 1 FROM [dbo].[Users] WHERE [UserId] = N'SYSTEM')
    INSERT INTO [dbo].[Users] ([UserId], [Email], [Department], [FirstName], [LastName], [CreatedBy])
    VALUES (N'SYSTEM', N'system@example.com', N'IT', N'System', N'User', N'SYSTEM');
GO

:r ../dbo/Tables/Roles.sql
GO

/* Seed the system roles (same seed as Seeds/RolesSeed.sql for project deploys). */
INSERT INTO [dbo].[Roles] ([Name], [Description], [IsSystemRole], [CreatedBy])
VALUES 
    (N'Developer', N'Developer role with full access to all resources including settings', 1, N'SYSTEM'),
    (N'Admin', N'Administrator role with full access to main resource topics', 1, N'SYSTEM'),
    (N'Viewer', N'Read-only access to all resources', 1, N'SYSTEM');
GO

/* UserRoles junction table (depends on Users and Roles created above). */
:r ../dbo/Tables/UserRoles.sql
GO
:r ../dbo/Tables/RuleContextObjects.sql
GO
:r ../dbo/Tables/GlobalSettings.sql
GO
:r ../dbo/Tables/ResourcePermissions.sql
GO
:r ../dbo/Tables/RolePermissions.sql
GO
/* RBAC/UI tables (depend on Users, Roles, and ResourcePermissions created above). */
:r ../dbo/Tables/UIPages.sql
GO
:r ../dbo/Tables/UIActions.sql
GO
:r ../dbo/Tables/PermissionToUIPageMapping.sql
GO
:r ../dbo/Tables/UserPermissions.sql
GO
:r ../dbo/Tables/UserActivities.sql
GO
:r ../dbo/Tables/UserSettings.sql
GO
:r ../dbo/Tables/RuleSets.sql
GO
:r ../dbo/Tables/RuleSetsPermissions.sql
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
:r ../dbo/Tables/ServiceOperations.sql
GO
:r ../dbo/Tables/ServiceOperationSchemas.sql
GO
:r ../dbo/Tables/SoapNamespaces.sql
GO
:r ../dbo/Tables/BinaryEmbeddingsStore.sql
GO
:r ../dbo/Tables/ServiceRequestFiles.sql
GO
:r ../dbo/Tables/ServiceRequestFilesPermissions.sql
GO
:r ../dbo/Tables/ServiceRequestFileEmbeddings.sql
GO
:r ../dbo/Tables/ServiceRequestIndexingStatus.sql
GO
:r ../dbo/Tables/ServiceResponseFiles.sql
GO
:r ../dbo/Tables/ServiceResponseFileEmbeddings.sql
GO
:r ../dbo/Tables/ServiceResponseIndexingStatus.sql
GO
:r ../dbo/Tables/ServiceTestCases.sql
GO
:r ../dbo/Tables/ServiceTestCasesPermissions.sql
GO
:r ../dbo/Tables/ServiceTestSuites.sql
GO
:r ../dbo/Tables/ServiceTestSuitesPermissions.sql
GO
:r ../dbo/Tables/ServiceTestCaseRuleSetLinks.sql
GO
:r ../dbo/Tables/ServiceTestSuiteTestCaseLinks.sql
GO
:r ../dbo/Tables/ServiceTestSuiteExecutionAudits.sql
GO
:r ../dbo/Tables/ServiceTestSuiteExecutionAuditTestCaseLinks.sql
GO
:r ../dbo/Tables/DirectExecutionAudit.sql
GO
:r ../dbo/Tables/DirectExecutionAuditResponseFileLinks.sql
GO
:r ../dbo/Tables/IndexingXmlFileElements.sql
GO
:r ../dbo/Tables/IndexingXmlFileElementSearch.sql
GO
:r ../dbo/Tables/IndexingXmlFileElementMappings.sql
GO
:r ../dbo/Tables/IndexingJsonFileElements.sql
GO
:r ../dbo/Tables/IndexingJsonFileElementSearch.sql
GO
:r ../dbo/Tables/IndexingJsonFileElementMappings.sql
GO
:r ../dbo/Tables/IndexingPdfFileElements.sql
GO
:r ../dbo/Tables/IndexingPdfFileElementSearch.sql
GO
:r ../dbo/Tables/IndexingPdfFileElementMappings.sql
GO

/* The full-text catalog and index are no longer created by this script.
   The old IndexingFileElementSearch denormalized table has been replaced
   by per-type element search tables (IndexingXmlFileElementSearch,
   IndexingJsonFileElementSearch, IndexingPdfFileElementSearch).
   The usp_SearchIndexingElements procedure now uses LIKE-based search via the
   v_IndexingFileElementSearch view instead of FREETEXTTABLE. */
GO

/* =====================================================================
   Recreate views and stored procedures from project source.
   Comment out this section to keep the tables-only reset behavior.
   NOTE: v_IndexingFileElementSearch must be created before
   v_IndexingElementSearchByValue (it depends on it).
   ===================================================================== */
:r ../dbo/Views/v_ActiveServiceOperations.sql
GO
:r ../dbo/Views/v_ActiveSoapNamespaces.sql
GO
:r ../dbo/Views/v_BinaryEmbeddingsByFormat.sql
GO
:r ../dbo/Views/v_BinaryEmbeddingsStorageSummary.sql
GO
:r ../dbo/Views/v_BinaryEmbeddingsStoreWithUsage.sql
GO
:r ../dbo/Views/v_GlobalSettingsWithDetails.sql
GO
:r ../dbo/Views/v_IndexingElementUsageStats.sql
GO
:r ../dbo/Views/v_IndexingFileElementSearch.sql
GO
:r ../dbo/Views/v_IndexingElementSearchByValue.sql
GO
:r ../dbo/Views/v_IndexingPendingQueue.sql
GO
:r ../dbo/Views/v_LatestServiceAppAuthentications.sql
GO
:r ../dbo/Views/v_LatestServiceApplicationsWithAuth.sql
GO
:r ../dbo/Views/v_ResourcePermissionsWithDetails.sql
GO
:r ../dbo/Views/v_RolePermissionSummary.sql
GO
:r ../dbo/Views/v_RolePermissionsWithDetails.sql
GO
:r ../dbo/Views/v_RolesWithDetails.sql
GO
:r ../dbo/Views/v_RuleContextObjectsWithUsage.sql
GO
:r ../dbo/Views/v_RuleExecutionLogsWithDetails.sql
GO
:r ../dbo/Views/v_RuleSetContextLinks.sql
GO
:r ../dbo/Views/v_RuleSetsWithDetails.sql
GO
:r ../dbo/Views/v_ServiceAppPermissionsSummary.sql
GO
:r ../dbo/Views/v_ServiceAppPermissionsWithDetails.sql
GO
:r ../dbo/Views/v_ServiceApplicationAudit.sql
GO
:r ../dbo/Views/v_ServiceDefinitionSyncsWithDetails.sql
GO
:r ../dbo/Views/v_ServiceOperationsSummary.sql
GO
:r ../dbo/Views/v_ServiceOperationsWithDetails.sql
GO
:r ../dbo/Views/v_ServiceRequestFileDeltaSummary.sql
GO
:r ../dbo/Views/v_ServiceRequestFileEmbeddingsWithDetails.sql
GO
:r ../dbo/Views/v_ServiceRequestFilesWithDetails.sql
GO
:r ../dbo/Views/v_ServiceRequestResponsePairs.sql
GO
:r ../dbo/Views/v_ServiceResponseFileDeltaSummary.sql
GO
:r ../dbo/Views/v_ServiceResponseFileEmbeddingsWithDetails.sql
GO
:r ../dbo/Views/v_ServiceResponseFilesWithDetails.sql
GO
:r ../dbo/Views/v_ServiceTestCaseExecutionHistory.sql
GO
:r ../dbo/Views/v_ServiceTestCasesWithDetails.sql
GO
:r ../dbo/Views/v_ServiceTestSuiteExecutionAuditsWithDetails.sql
GO
:r ../dbo/Views/v_ServiceTestSuitesWithDetails.sql
GO
:r ../dbo/Views/v_SoapNamespacesSummary.sql
GO
:r ../dbo/Views/v_SoapNamespacesWithDetails.sql
GO
:r ../dbo/Views/v_UIActionsWithDetails.sql
GO
:r ../dbo/Views/v_UIPagesWithDetails.sql
GO
:r ../dbo/Views/v_UserPermissionsSummary.sql
GO
:r ../dbo/Views/v_UserPermissionSummary.sql
GO
:r ../dbo/Views/v_UserPermissionsWithDetails.sql
GO
:r ../dbo/Views/v_UserSettingsWithDetails.sql
GO

/* usp_InsertUserActivities is created first because many other procedures depend on it. */
:r ../dbo/StoredProcedures/usp_InsertUserActivities.sql
GO
:r ../dbo/StoredProcedures/usp_UpdateServiceOperationsActivate.sql
GO
:r ../dbo/StoredProcedures/usp_FindBinaryEmbeddingsStore.sql
GO
GO
:r ../dbo/StoredProcedures/usp_InsertDirectExecutionAuditWithActivity.sql
GO
:r ../dbo/StoredProcedures/usp_InsertDirectExecutionAuditResponseFileLink.sql
GO
:r ../dbo/StoredProcedures/usp_InsertGlobalSettings.sql
GO
:r ../dbo/StoredProcedures/usp_InsertResourcePermissions.sql
GO
:r ../dbo/StoredProcedures/usp_InsertRoles.sql
GO
:r ../dbo/StoredProcedures/usp_InsertRolePermissions.sql
GO
:r ../dbo/StoredProcedures/usp_InsertRuleContextObjects.sql
GO
:r ../dbo/StoredProcedures/usp_InsertRuleSets.sql
GO
:r ../dbo/StoredProcedures/usp_InsertServiceApplications.sql
GO
:r ../dbo/StoredProcedures/usp_InsertServiceOperations.sql
GO
:r ../dbo/StoredProcedures/usp_InsertServiceOperationSchemas.sql
GO
:r ../dbo/StoredProcedures/usp_InsertServiceOperationWithSchema.sql
GO
:r ../dbo/StoredProcedures/usp_InsertServiceTestCases.sql
GO
:r ../dbo/StoredProcedures/usp_InsertServiceTestSuites.sql
GO
:r ../dbo/StoredProcedures/usp_InsertSoapNamespaces.sql
GO
:r ../dbo/StoredProcedures/usp_InsertServiceTestSuiteExecutionAudits.sql
GO
:r ../dbo/StoredProcedures/usp_InsertUIActions.sql
GO
:r ../dbo/StoredProcedures/usp_InsertUIPages.sql
GO
:r ../dbo/StoredProcedures/usp_InsertUserPermissions.sql
GO
:r ../dbo/StoredProcedures/usp_DeleteUserPermissions.sql
GO
:r ../dbo/StoredProcedures/usp_FindBinaryEmbeddingsStoreByContentHash.sql
GO
:r ../dbo/StoredProcedures/usp_GetResourcePermissionsAvailable.sql
GO
:r ../dbo/StoredProcedures/usp_GetBinaryEmbeddingsStore.sql
GO
:r ../dbo/StoredProcedures/usp_GetIndexingFileElementsFrequency.sql
GO
:r ../dbo/StoredProcedures/usp_GetIndexingFileElementsFiles.sql
GO
:r ../dbo/StoredProcedures/usp_GetGlobalSettings.sql
GO
:r ../dbo/StoredProcedures/usp_GetIndexingFileElementsStatistics.sql
GO
:r ../dbo/StoredProcedures/usp_GetRolePermissions.sql
GO
:r ../dbo/StoredProcedures/usp_GetRoles.sql
GO
:r ../dbo/StoredProcedures/usp_GetRuleExecutionLogsStatistics.sql
GO
:r ../dbo/StoredProcedures/usp_GetServiceAppPermissions.sql
GO
:r ../dbo/StoredProcedures/usp_GetServiceApplicationsHistory.sql
GO
:r ../dbo/StoredProcedures/usp_GetServiceOperations.sql
GO
:r ../dbo/StoredProcedures/usp_GetServiceRequestFilesChain.sql
GO
:r ../dbo/StoredProcedures/usp_GetServiceRequestFilesConsecutiveDeltaCount.sql
GO
:r ../dbo/StoredProcedures/usp_GetServiceRequestFilesByOperation.sql
GO
:r ../dbo/StoredProcedures/usp_GetServiceResponseFileChain.sql
GO
:r ../dbo/StoredProcedures/usp_GetServiceResponseFilesByRequest.sql
GO
:r ../dbo/StoredProcedures/usp_GetSoapNamespaces.sql
GO
:r ../dbo/StoredProcedures/usp_GetServiceTestSuiteExecutionAuditsSummary.sql
GO
:r ../dbo/StoredProcedures/usp_GetUserPermissions.sql
GO
:r ../dbo/StoredProcedures/usp_InsertBinaryEmbeddingsStore.sql
GO
:r ../dbo/StoredProcedures/usp_InsertDirectExecutionAuditSimple.sql
GO
:r ../dbo/StoredProcedures/usp_InsertServiceDefinitionSyncs.sql
GO
:r ../dbo/StoredProcedures/usp_InsertServiceRequestFiles.sql
GO
:r ../dbo/StoredProcedures/usp_InsertServiceRequestFileEmbeddings.sql
GO
:r ../dbo/StoredProcedures/usp_InsertServiceResponseFiles.sql
GO
:r ../dbo/StoredProcedures/usp_InsertServiceResponseFileEmbedding.sql
GO
:r ../dbo/StoredProcedures/usp_InsertOrGetIndexingXmlFileElements.sql
GO
:r ../dbo/StoredProcedures/usp_InsertOrGetIndexingXmlFileElementSearch.sql
GO
:r ../dbo/StoredProcedures/usp_InsertIndexingXmlFileElementMappingsSingle.sql
GO
:r ../dbo/StoredProcedures/usp_InsertOrGetIndexingJsonFileElements.sql
GO
:r ../dbo/StoredProcedures/usp_InsertOrGetIndexingJsonFileElementSearch.sql
GO
:r ../dbo/StoredProcedures/usp_InsertIndexingJsonFileElementMappings.sql
GO
:r ../dbo/StoredProcedures/usp_InsertOrGetIndexingPdfFileElements.sql
GO
:r ../dbo/StoredProcedures/usp_InsertOrGetIndexingPdfFileElementSearch.sql
GO
:r ../dbo/StoredProcedures/usp_InsertIndexingPdfFileElementMappings.sql
GO
:r ../dbo/StoredProcedures/usp_InsertRuleSetContextObjectLinks.sql
GO
:r ../dbo/StoredProcedures/usp_InsertServiceTestCaseRuleSetLinks.sql
GO
:r ../dbo/StoredProcedures/usp_InsertServiceTestSuiteTestCaseLinks.sql
GO
:r ../dbo/StoredProcedures/usp_InsertRuleExecutionLogs.sql
GO
:r ../dbo/StoredProcedures/usp_InsertServiceTestSuiteExecutionAuditTestCaseLinks.sql
GO
:r ../dbo/StoredProcedures/usp_DeleteServiceAppPermissions.sql
GO
:r ../dbo/StoredProcedures/usp_InsertServiceDefinitionSyncsWithOperations.sql
GO
/* usp_SearchIndexingElements is recreated below using LIKE-based search via the
   v_IndexingFileElementSearch view (no longer uses FREETEXTTABLE). */
:r ../dbo/StoredProcedures/usp_SearchIndexingElements.sql
GO
:r ../dbo/StoredProcedures/usp_UpdateServiceApplicationsActive.sql
GO
:r ../dbo/StoredProcedures/usp_DeleteRuleSetContextObjectLinks.sql
GO
:r ../dbo/StoredProcedures/usp_DeleteServiceTestCaseRuleSetLinks.sql
GO
:r ../dbo/StoredProcedures/usp_DeleteServiceTestSuiteTestCaseLinks.sql
GO
:r ../dbo/StoredProcedures/usp_UpdateBinaryEmbeddingsStore.sql
GO
:r ../dbo/StoredProcedures/usp_UpdateDirectExecutionAudit.sql
GO
:r ../dbo/StoredProcedures/usp_UpdateDirectExecutionAuditResponseFileLinks.sql
GO
:r ../dbo/StoredProcedures/usp_UpdateGlobalSettings.sql
GO
:r ../dbo/StoredProcedures/usp_UpdateResourcePermissions.sql
GO
:r ../dbo/StoredProcedures/usp_UpdateRoles.sql
GO
:r ../dbo/StoredProcedures/usp_UpdateRolePermissions.sql
GO
:r ../dbo/StoredProcedures/usp_UpdateRuleContextObjects.sql
GO
:r ../dbo/StoredProcedures/usp_UpdateRuleSets.sql
GO
:r ../dbo/StoredProcedures/usp_UpdateServiceAppAuthentications.sql
GO
:r ../dbo/StoredProcedures/usp_UpdateServiceDefinitionSyncs.sql
GO
:r ../dbo/StoredProcedures/usp_UpdateServiceOperations.sql
GO
:r ../dbo/StoredProcedures/usp_UpdateServiceOperationSchemas.sql
GO
:r ../dbo/StoredProcedures/usp_UpdateServiceRequestFiles.sql
GO
:r ../dbo/StoredProcedures/usp_UpdateServiceRequestFileEmbeddings.sql
GO
:r ../dbo/StoredProcedures/usp_InsertAndUpdateServiceRequestFiles.sql
GO
:r ../dbo/StoredProcedures/usp_UpdateServiceResponseFiles.sql
GO
:r ../dbo/StoredProcedures/usp_UpdateServiceResponseFileEmbeddings.sql
GO
:r ../dbo/StoredProcedures/usp_UpdateServiceTestCases.sql
GO
:r ../dbo/StoredProcedures/usp_UpdateServiceTestSuites.sql
GO
:r ../dbo/StoredProcedures/usp_UpdateSoapNamespaces.sql
GO
:r ../dbo/StoredProcedures/usp_UpdateServiceTestSuiteExecutionAuditTestCaseLinks.sql
GO
:r ../dbo/StoredProcedures/usp_UpdateUIActions.sql
GO
:r ../dbo/StoredProcedures/usp_UpdateUIPages.sql
GO
:r ../dbo/StoredProcedures/usp_UpdateUserPermissions.sql
GO
:r ../dbo/StoredProcedures/usp_UpdateUserSettings.sql
GO
:r ../dbo/StoredProcedures/usp_InsertAndUpdateServiceAppPermissions.sql
GO
:r ../dbo/StoredProcedures/usp_InsertAndUpdateServiceApplications.sql
GO

/* Apply documentation after all tables, views, and stored procedures are available. */
:r ApplyColumnDescriptions.sql
GO

PRINT N'OrbitTool schema reset and recreation completed successfully.';
GO
