/*
    OrbitTool database reset and schema recreation script.
    Run from OrbitToolDatabase/scripts with SQLCMD while connected to the OrbitTool server.

    This script resets and recreates the FULL schema from the SQL project source in ../dbo.
    It drops every view, stored procedure, user-defined type, foreign key, table
    (most-dependent first), the IndexingCatalog full-text catalog (legacy cleanup), and
    the fn_CalculateVersion function; then recreates the function, all tables (honoring
    foreign-key dependencies), all user-defined types, all views, all stored procedures,
    and applies column descriptions.

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

/* Drop user-defined table types (must be dropped after procedures that use them). */
IF EXISTS (SELECT 1 FROM sys.types WHERE name = N'ServiceOperationSchemaInput' AND is_user_defined = 1)
    DROP TYPE [dbo].[ServiceOperationSchemaInput];
GO
IF EXISTS (SELECT 1 FROM sys.types WHERE name = N'ServiceRequestFileEmbeddingLinkInput' AND is_user_defined = 1)
    DROP TYPE [dbo].[ServiceRequestFileEmbeddingLinkInput];
GO

/* Drop tables from most-dependent to least-dependent. */

/* Indexing mapping / value tables */
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.IndexingPdfFileElementMappings')) DROP TABLE [dbo].[IndexingPdfFileElementMappings];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.IndexingPdfFileElementValues')) DROP TABLE [dbo].[IndexingPdfFileElementValues];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.IndexingPdfFileElements')) DROP TABLE [dbo].[IndexingPdfFileElements];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.IndexingJsonRequestResponseMappings')) DROP TABLE [dbo].[IndexingJsonRequestResponseMappings];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.IndexingJsonFileElementValues')) DROP TABLE [dbo].[IndexingJsonFileElementValues];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.IndexingJsonFileElements')) DROP TABLE [dbo].[IndexingJsonFileElements];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.IndexingXmlRequestResponseMappings')) DROP TABLE [dbo].[IndexingXmlRequestResponseMappings];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.IndexingXmlFileElementValues')) DROP TABLE [dbo].[IndexingXmlFileElementValues];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.IndexingXmlFileElements')) DROP TABLE [dbo].[IndexingXmlFileElements];

/* Indexing status tables */
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.IndexingServiceResponseFileStatus')) DROP TABLE [dbo].[IndexingServiceResponseFileStatus];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.IndexingServiceRequestFileStatus')) DROP TABLE [dbo].[IndexingServiceRequestFileStatus];

/* DirectExecution audit / link tables */
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.DirectExecutionGroupServiceRequestFileLinkAudits')) DROP TABLE [dbo].[DirectExecutionGroupServiceRequestFileLinkAudits];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.DirectExecutionGroupAudits')) DROP TABLE [dbo].[DirectExecutionGroupAudits];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.DirectExecutionGroupServiceRequestFileLinks')) DROP TABLE [dbo].[DirectExecutionGroupServiceRequestFileLinks];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.DirectExecutionGroups')) DROP TABLE [dbo].[DirectExecutionGroups];

/* Service App health check links */
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceAppHealthHttpExecutionDetailAuditLinks')) DROP TABLE [dbo].[ServiceAppHealthHttpExecutionDetailAuditLinks];

/* Test Suite execution / link tables */
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceTestSuiteTestCaseLinkAudits')) DROP TABLE [dbo].[ServiceTestSuiteTestCaseLinkAudits];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceTestSuiteExecutionAudits')) DROP TABLE [dbo].[ServiceTestSuiteExecutionAudits];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceTestSuiteTestCaseLinks')) DROP TABLE [dbo].[ServiceTestSuiteTestCaseLinks];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceTestCaseRuleSetLinks')) DROP TABLE [dbo].[ServiceTestCaseRuleSetLinks];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceTestSuites')) DROP TABLE [dbo].[ServiceTestSuites];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceTestCases')) DROP TABLE [dbo].[ServiceTestCases];

/* Service Response file tables */
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceResponseFilesDatabaseAudits')) DROP TABLE [dbo].[ServiceResponseFilesDatabaseAudits];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.HttpExecutionDetailAuditsServiceResponseFilesLinks')) DROP TABLE [dbo].[HttpExecutionDetailAuditsServiceResponseFilesLinks];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceResponseFileHttpExecutionDetailLinks')) DROP TABLE [dbo].[ServiceResponseFileHttpExecutionDetailLinks];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceResponseFileBinaryEmbeddingStoreLinks')) DROP TABLE [dbo].[ServiceResponseFileBinaryEmbeddingStoreLinks];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceResponseFiles')) DROP TABLE [dbo].[ServiceResponseFiles];

/* HTTP Execution Detail Audits */
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.HttpExecutionDetailAudits')) DROP TABLE [dbo].[HttpExecutionDetailAudits];

/* Service Request file tables */
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceRequestFileBinaryEmbeddingStoreLinks')) DROP TABLE [dbo].[ServiceRequestFileBinaryEmbeddingStoreLinks];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceRequestFiles')) DROP TABLE [dbo].[ServiceRequestFiles];

/* Binary embedding store */
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.BinaryEmbeddingStores')) DROP TABLE [dbo].[BinaryEmbeddingStores];

/* Service Operation / Schema tables */
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.SoapNamespaces')) DROP TABLE [dbo].[SoapNamespaces];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceOperationSchemas')) DROP TABLE [dbo].[ServiceOperationSchemas];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceOperations')) DROP TABLE [dbo].[ServiceOperations];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceDefinitionSyncs')) DROP TABLE [dbo].[ServiceDefinitionSyncs];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.ServiceApplications')) DROP TABLE [dbo].[ServiceApplications];

/* Rule Engine tables */
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.RuleSetExecutionAudits')) DROP TABLE [dbo].[RuleSetExecutionAudits];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.RuleSetRuleContextObjectLinks')) DROP TABLE [dbo].[RuleSetRuleContextObjectLinks];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.RuleSets')) DROP TABLE [dbo].[RuleSets];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.RuleSetContextObjects')) DROP TABLE [dbo].[RuleSetContextObjects];

/* User Setting and Activity tables */
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.UserSettings')) DROP TABLE [dbo].[UserSettings];
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.UserActivities')) DROP TABLE [dbo].[UserActivities];

/* Global Settings */
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.GlobalSettings')) DROP TABLE [dbo].[GlobalSettings];

/* Users (last — referenced as FK by all other tables) */
IF EXISTS (SELECT 1 FROM sys.tables WHERE object_id = OBJECT_ID(N'dbo.Users')) DROP TABLE [dbo].[Users];
GO

/* Drop the full-text catalog if it still exists (legacy cleanup). */
IF EXISTS (SELECT 1 FROM sys.fulltext_catalogs WHERE name = N'IndexingCatalog')
    DROP FULLTEXT CATALOG [IndexingCatalog];
GO

/* Drop any default constraints still referencing fn_CalculateVersion
   (covers legacy / renamed tables not in the explicit drop list above). */
DECLARE @DefSchema   sysname;
DECLARE @DefTable    sysname;
DECLARE @DefName     sysname;
DECLARE @DefDropSql  nvarchar(max);

DECLARE DefaultConstraintCursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT
        SCHEMA_NAME(tbl.schema_id),
        tbl.name,
        dc.name
    FROM sys.default_constraints AS dc
    INNER JOIN sys.tables AS tbl
        ON tbl.object_id = dc.parent_object_id
    WHERE dc.definition LIKE N'%fn_CalculateVersion%';

OPEN DefaultConstraintCursor;
FETCH NEXT FROM DefaultConstraintCursor INTO @DefSchema, @DefTable, @DefName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @DefDropSql =
        N'ALTER TABLE ' + QUOTENAME(@DefSchema) + N'.' + QUOTENAME(@DefTable) +
        N' DROP CONSTRAINT ' + QUOTENAME(@DefName) + N';';
    EXEC sys.sp_executesql @DefDropSql;

    FETCH NEXT FROM DefaultConstraintCursor INTO @DefSchema, @DefTable, @DefName;
END;

CLOSE DefaultConstraintCursor;
DEALLOCATE DefaultConstraintCursor;
GO

/* Drop function after tables and any lingering default constraints. */
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

/* =====================================================================
   Recreate tables from project source, honoring foreign-key dependencies.
   ===================================================================== */

/* Foundation — Users first (self-referencing FK; all other tables point here) */
:r ../dbo/Tables/Users.sql
GO

/* Seed the SYSTEM user so every subsequent table that sets CreatedBy = N'SYSTEM'
   satisfies its FK_*_Users_CreatedBy constraint. */
IF NOT EXISTS (SELECT 1 FROM [dbo].[Users] WHERE [UserId] = N'SYSTEM')
    INSERT INTO [dbo].[Users] ([UserId], [Email], [Department], [FirstName], [LastName], [CreatedBy])
    VALUES (N'SYSTEM', N'system@example.com', N'IT', N'System', N'User', NULL);
GO

/* Global Settings and User configuration */
:r ../dbo/Tables/GlobalSettings.sql
GO
:r ../dbo/Tables/UserSettings.sql
GO
:r ../dbo/Tables/UserActivities.sql
GO

/* Rule Engine — context objects before rule sets */
:r ../dbo/Tables/RuleSetContextObjects.sql
GO
:r ../dbo/Tables/RuleSets.sql
GO
:r ../dbo/Tables/RuleSetRuleContextObjectLinks.sql
GO
:r ../dbo/Tables/RuleSetExecutionAudits.sql
GO

/* Service Applications (no FK to Users; standalone root) */
:r ../dbo/Tables/ServiceApplications.sql
GO
:r ../dbo/Tables/ServiceDefinitionSyncs.sql
GO
:r ../dbo/Tables/ServiceOperations.sql
GO
:r ../dbo/Tables/ServiceOperationSchemas.sql
GO
:r ../dbo/Tables/SoapNamespaces.sql
GO

/* Binary Embedding Stores (standalone) */
:r ../dbo/Tables/BinaryEmbeddingStores.sql
GO

/* Service Request Files and links */
:r ../dbo/Tables/ServiceRequestFiles.sql
GO
:r ../dbo/Tables/ServiceRequestFileBinaryEmbeddingStoreLinks.sql
GO

/* HTTP Execution Detail Audits (before ServiceResponseFiles and health links) */
:r ../dbo/Tables/HttpExecutionDetailAudits.sql
GO

/* Service Response Files and links */
:r ../dbo/Tables/ServiceResponseFiles.sql
GO
:r ../dbo/Tables/ServiceResponseFileBinaryEmbeddingStoreLinks.sql
GO
:r ../dbo/Tables/ServiceResponseFileHttpExecutionDetailLinks.sql
GO
:r ../dbo/Tables/HttpExecutionDetailAuditsServiceResponseFilesLinks.sql
GO
:r ../dbo/Tables/ServiceResponseFilesDatabaseAudits.sql
GO

/* Service App health check links (depends on ServiceApplications + HttpExecutionDetailAudits) */
:r ../dbo/Tables/ServiceAppHealthHttpExecutionDetailAuditLinks.sql
GO

/* Test Suite and Test Case tables */
:r ../dbo/Tables/ServiceTestCases.sql
GO
:r ../dbo/Tables/ServiceTestCaseRuleSetLinks.sql
GO
:r ../dbo/Tables/ServiceTestSuites.sql
GO
:r ../dbo/Tables/ServiceTestSuiteTestCaseLinks.sql
GO
:r ../dbo/Tables/ServiceTestSuiteTestCaseLinkAudits.sql
GO
:r ../dbo/Tables/ServiceTestSuiteExecutionAudits.sql
GO

/* Direct Execution Group tables */
:r ../dbo/Tables/DirectExecutionGroups.sql
GO
:r ../dbo/Tables/DirectExecutionGroupServiceRequestFileLinks.sql
GO
:r ../dbo/Tables/DirectExecutionGroupAudits.sql
GO
:r ../dbo/Tables/DirectExecutionGroupServiceRequestFileLinkAudits.sql
GO

/* Indexing — XML */
:r ../dbo/Tables/IndexingXmlFileElements.sql
GO
:r ../dbo/Tables/IndexingXmlFileElementValues.sql
GO
:r ../dbo/Tables/IndexingXmlRequestResponseMappings.sql
GO

/* Indexing — JSON */
:r ../dbo/Tables/IndexingJsonFileElements.sql
GO
:r ../dbo/Tables/IndexingJsonFileElementValues.sql
GO
:r ../dbo/Tables/IndexingJsonRequestResponseMappings.sql
GO

/* Indexing — PDF */
:r ../dbo/Tables/IndexingPdfFileElements.sql
GO
:r ../dbo/Tables/IndexingPdfFileElementValues.sql
GO
:r ../dbo/Tables/IndexingPdfFileElementMappings.sql
GO

/* Indexing status tables */
:r ../dbo/Tables/IndexingServiceRequestFileStatus.sql
GO
:r ../dbo/Tables/IndexingServiceResponseFileStatus.sql
GO

/* =====================================================================
   Recreate user-defined table types from project source.
   ===================================================================== */
:r ../dbo/Types/ServiceOperationSchemaInput.sql
GO
:r ../dbo/Types/ServiceRequestFileEmbeddingLinkInput.sql
GO

/* =====================================================================
   Recreate views from project source.
   Comment out this section to keep the tables-only reset behavior.
   ===================================================================== */
:r ../dbo/Views/vw_ServiceApplicationLatestDefinition.sql
GO
:r ../dbo/Views/vw_ServiceApplicationLatestOperations.sql
GO
:r ../dbo/Views/vw_ServiceOperationLatestSchema.sql
GO
:r ../dbo/Views/vw_ServiceRequestFileLatest.sql
GO
:r ../dbo/Views/vw_ServiceRequestFileWithLinks.sql
GO

/* =====================================================================
   Recreate stored procedures from project source.
   Comment out this section to keep the tables-only reset behavior.
   ===================================================================== */

/* Query / Getter Procedures */
:r ../dbo/StoredProcedures/usp_GetServiceDefinitions.sql
GO
:r ../dbo/StoredProcedures/usp_GetServiceOperations.sql
GO
:r ../dbo/StoredProcedures/usp_GetServiceOperation.sql
GO
:r ../dbo/StoredProcedures/usp_GetServiceOperationSchema.sql
GO
:r ../dbo/StoredProcedures/usp_GetServiceRequestFiles.sql
GO
:r ../dbo/StoredProcedures/usp_GetServiceRequestFile.sql
GO
:r ../dbo/StoredProcedures/usp_GetServiceApplicationGenerationSnapshot.sql
GO

/* Save / Upsert Procedures */
:r ../dbo/StoredProcedures/usp_SaveServiceDefinitionSync.sql
GO
:r ../dbo/StoredProcedures/usp_SaveServiceDefinitionWithOperations.sql
GO
:r ../dbo/StoredProcedures/usp_SaveServiceOperation.sql
GO
:r ../dbo/StoredProcedures/usp_SaveServiceOperationSchema.sql
GO
:r ../dbo/StoredProcedures/usp_SaveServiceRequestFile.sql
GO
:r ../dbo/StoredProcedures/usp_SaveBinaryEmbeddingStore.sql
GO

:r ApplyColumnDescriptions.sql
GO

PRINT N'OrbitTool schema reset and recreation completed successfully.';
GO