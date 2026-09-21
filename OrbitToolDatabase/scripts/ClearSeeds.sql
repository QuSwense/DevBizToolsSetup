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

PRINT 'Clearing Indexing mapping/value tables...';
DELETE FROM [dbo].[IndexingPdfFileElementMappings];
DELETE FROM [dbo].[IndexingPdfFileElementValues];
DELETE FROM [dbo].[IndexingPdfFileElements];
DELETE FROM [dbo].[IndexingJsonRequestResponseMappings];
DELETE FROM [dbo].[IndexingJsonFileElementValues];
DELETE FROM [dbo].[IndexingJsonFileElements];
DELETE FROM [dbo].[IndexingXmlRequestResponseMappings];
DELETE FROM [dbo].[IndexingXmlFileElementValues];
DELETE FROM [dbo].[IndexingXmlFileElements];
PRINT '  Indexing mapping/value tables cleared.';
GO

PRINT 'Clearing Indexing status tables...';
DELETE FROM [dbo].[IndexingServiceResponseFileStatus];
DELETE FROM [dbo].[IndexingServiceRequestFileStatus];
PRINT '  Indexing status tables cleared.';
GO

PRINT 'Clearing DirectExecution audit/link tables...';
DELETE FROM [dbo].[DirectExecutionGroupServiceRequestFileLinkAudits];
DELETE FROM [dbo].[DirectExecutionGroupAudits];
DELETE FROM [dbo].[DirectExecutionGroupServiceRequestFileLinks];
DELETE FROM [dbo].[DirectExecutionGroups];
PRINT '  DirectExecution audit/link tables cleared.';
GO

PRINT 'Clearing Service App health check links...';
DELETE FROM [dbo].[ServiceAppHealthHttpExecutionDetailAuditLinks];
PRINT '  ServiceAppHealthHttpExecutionDetailAuditLinks cleared.';
GO

PRINT 'Clearing Test Suite execution/link tables...';
DELETE FROM [dbo].[ServiceTestSuiteTestCaseLinkAudits];
DELETE FROM [dbo].[ServiceTestSuiteExecutionAudits];
DELETE FROM [dbo].[ServiceTestSuiteTestCaseLinks];
DELETE FROM [dbo].[ServiceTestCaseRuleSetLinks];
DELETE FROM [dbo].[ServiceTestSuites];
DELETE FROM [dbo].[ServiceTestCases];
PRINT '  Test Suite execution/link tables cleared.';
GO

PRINT 'Clearing Service Response file tables...';
DELETE FROM [dbo].[ServiceResponseFilesDatabaseAudits];
DELETE FROM [dbo].[HttpExecutionDetailAuditsServiceResponseFilesLinks];
DELETE FROM [dbo].[ServiceResponseFileHttpExecutionDetailLinks];
DELETE FROM [dbo].[ServiceResponseFileBinaryEmbeddingStoreLinks];
DELETE FROM [dbo].[ServiceResponseFiles];
PRINT '  Service Response file tables cleared.';
GO

PRINT 'Clearing HTTP Execution Detail Audits...';
DELETE FROM [dbo].[HttpExecutionDetailAudits];
PRINT '  HttpExecutionDetailAudits cleared.';
GO

PRINT 'Clearing Service Request file tables...';
DELETE FROM [dbo].[ServiceRequestFileBinaryEmbeddingStoreLinks];
DELETE FROM [dbo].[ServiceRequestFiles];
PRINT '  Service Request file tables cleared.';
GO

PRINT 'Clearing BinaryEmbeddingStores...';
DELETE FROM [dbo].[BinaryEmbeddingStores];
PRINT '  BinaryEmbeddingStores cleared.';
GO

PRINT 'Clearing Service Operation/Schema tables...';
DELETE FROM [dbo].[SoapNamespaces];
DELETE FROM [dbo].[ServiceOperationSchemas];
DELETE FROM [dbo].[ServiceOperations];
DELETE FROM [dbo].[ServiceDefinitionSyncs];
DELETE FROM [dbo].[ServiceApplications];
PRINT '  Service Operation/Schema tables cleared.';
GO

PRINT 'Clearing Rule Engine tables...';
DELETE FROM [dbo].[RuleSetExecutionAudits];
DELETE FROM [dbo].[RuleSetRuleContextObjectLinks];
DELETE FROM [dbo].[RuleSets];
DELETE FROM [dbo].[RuleSetContextObjects];
PRINT '  Rule Engine tables cleared.';
GO

PRINT 'Clearing User Settings and Activities...';
DELETE FROM [dbo].[UserSettings];
DELETE FROM [dbo].[UserActivities];
PRINT '  User Settings and Activities cleared.';
GO

PRINT 'Clearing GlobalSettings...';
DELETE FROM [dbo].[GlobalSettings];
PRINT '  GlobalSettings cleared.';
GO

PRINT 'Clearing Users...';
DELETE FROM [dbo].[Users];
PRINT '  Users cleared.';
GO

PRINT '========================================';
PRINT '  All table data cleared successfully!';
PRINT '========================================';
GO