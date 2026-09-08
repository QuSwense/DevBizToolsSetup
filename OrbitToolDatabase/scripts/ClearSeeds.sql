/*
    ClearSeeds.sql - Delete all data from all tables in FK-safe order

    This script deletes all rows from all tables in the correct order to respect
    foreign key constraints (most-dependent tables first). It uses DELETE without
    WHERE to clear all data while preserving the schema.

    Usage:
        SQLCMDPASSWORD='...' sqlcmd -S localhost,1433 -U sa -C -d OrbitTool -b -i ClearSeeds.sql
*/
:on error exit
:setvar DatabaseName "OrbitTool"

USE [$(DatabaseName)];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT '========================================';
PRINT '  Clearing all table data';
PRINT '========================================';
PRINT '';

-- Delete from most-dependent tables first (reverse FK order)

PRINT 'Clearing Indexing tables...';
DELETE FROM [dbo].[IndexingPdfFileElementSearch];
DELETE FROM [dbo].[IndexingPdfFileElementMappings];
DELETE FROM [dbo].[IndexingPdfFileElements];
DELETE FROM [dbo].[IndexingJsonFileElementSearch];
DELETE FROM [dbo].[IndexingJsonFileElementMappings];
DELETE FROM [dbo].[IndexingJsonFileElements];
DELETE FROM [dbo].[IndexingXmlFileElementSearch];
DELETE FROM [dbo].[IndexingXmlFileElementMappings];
DELETE FROM [dbo].[IndexingXmlFileElements];
PRINT '  Indexing tables cleared.';
GO

PRINT 'Clearing DirectExecution tables...';
DELETE FROM [dbo].[DirectExecutionAuditResponseFileLinks];
DELETE FROM [dbo].[DirectExecutionAudit];
PRINT '  DirectExecution tables cleared.';
GO

PRINT 'Clearing Test Suite execution tables...';
DELETE FROM [dbo].[ServiceTestSuiteExecutionAuditTestCaseLinks];
DELETE FROM [dbo].[ServiceTestSuiteExecutionAudits];
DELETE FROM [dbo].[ServiceTestSuiteTestCaseLinks];
DELETE FROM [dbo].[ServiceTestCaseRuleSetLinks];
PRINT '  Test Suite execution tables cleared.';
GO

PRINT 'Clearing Test Suite/Case permission tables...';
DELETE FROM [dbo].[ServiceTestSuitesPermissions];
DELETE FROM [dbo].[ServiceTestCasesPermissions];
PRINT '  Test Suite/Case permission tables cleared.';
GO

PRINT 'Clearing Test Suite/Case tables...';
DELETE FROM [dbo].[ServiceTestSuites];
DELETE FROM [dbo].[ServiceTestCases];
PRINT '  Test Suite/Case tables cleared.';
GO

PRINT 'Clearing Service Response tables...';
DELETE FROM [dbo].[ServiceResponseIndexingStatus];
DELETE FROM [dbo].[ServiceResponseFileEmbeddings];
DELETE FROM [dbo].[ServiceResponseFiles];
PRINT '  Service Response tables cleared.';
GO

PRINT 'Clearing Service Request tables...';
DELETE FROM [dbo].[ServiceRequestIndexingStatus];
DELETE FROM [dbo].[ServiceRequestFileEmbeddings];
DELETE FROM [dbo].[ServiceRequestFilesPermissions];
DELETE FROM [dbo].[ServiceRequestFiles];
PRINT '  Service Request tables cleared.';
GO

PRINT 'Clearing BinaryEmbeddingsStore...';
DELETE FROM [dbo].[BinaryEmbeddingsStore];
PRINT '  BinaryEmbeddingsStore cleared.';
GO

PRINT 'Clearing Service Operation/Schema tables...';
DELETE FROM [dbo].[SoapNamespaces];
DELETE FROM [dbo].[ServiceOperationSchemas];
DELETE FROM [dbo].[ServiceOperations];
DELETE FROM [dbo].[ServiceDefinitionSyncs];
PRINT '  Service Operation/Schema tables cleared.';
GO

PRINT 'Clearing Service Application permission tables...';
DELETE FROM [dbo].[ServiceAppPermissions];
PRINT '  Service Application permission tables cleared.';
GO

PRINT 'Clearing Service Applications...';
DELETE FROM [dbo].[ServiceApplications];
PRINT '  Service Applications cleared.';
GO

PRINT 'Clearing ServiceAppAuthentications...';
DELETE FROM [dbo].[ServiceAppAuthentications];
PRINT '  ServiceAppAuthentications cleared.';
GO

PRINT 'Clearing Rule Engine tables...';
DELETE FROM [dbo].[RuleExecutionLogs];
DELETE FROM [dbo].[RuleSetContextObjectLinks];
DELETE FROM [dbo].[RuleSetsPermissions];
DELETE FROM [dbo].[RuleSets];
PRINT '  Rule Engine tables cleared.';
GO

PRINT 'Clearing User Settings and Activities...';
DELETE FROM [dbo].[UserSettings];
DELETE FROM [dbo].[UserActivities];
DELETE FROM [dbo].[UserPermissions];
PRINT '  User Settings and Activities cleared.';
GO

PRINT 'Clearing RolePermissions...';
DELETE FROM [dbo].[RolePermissions];
PRINT '  RolePermissions cleared.';
GO

PRINT 'Clearing PermissionToUIPageMapping...';
DELETE FROM [dbo].[PermissionToUIPageMapping];
PRINT '  PermissionToUIPageMapping cleared.';
GO

PRINT 'Clearing UIActions...';
DELETE FROM [dbo].[UIActions];
PRINT '  UIActions cleared.';
GO

PRINT 'Clearing UIPages...';
DELETE FROM [dbo].[UIPages];
PRINT '  UIPages cleared.';
GO

PRINT 'Clearing ResourcePermissions...';
DELETE FROM [dbo].[ResourcePermissions];
PRINT '  ResourcePermissions cleared.';
GO

PRINT 'Clearing GlobalSettings...';
DELETE FROM [dbo].[GlobalSettings];
PRINT '  GlobalSettings cleared.';
GO

PRINT 'Clearing RuleContextObjects...';
DELETE FROM [dbo].[RuleContextObjects];
PRINT '  RuleContextObjects cleared.';
GO

PRINT 'Clearing Roles...';
DELETE FROM [dbo].[Roles];
PRINT '  Roles cleared.';
GO

PRINT 'Clearing Users...';
DELETE FROM [dbo].[Users];
PRINT '  Users cleared.';
GO

PRINT '========================================';
PRINT '  All table data cleared successfully!';
PRINT '========================================';
GO