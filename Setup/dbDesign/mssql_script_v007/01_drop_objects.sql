-- ============================================================================
-- SCRIPT 1: DROP FOREIGN KEYS, INDEXES, AND TABLES
-- Target Engine: Microsoft SQL Server
-- Description: Cleanly drops all REST, SOAP, Rules, and Generic objects.
-- ============================================================================

SET NOCOUNT ON;

-- ----------------------------------------------------------------------------
-- 1. DROP REST FOREIGN KEYS
-- ----------------------------------------------------------------------------
IF OBJECT_ID('dbo.FK_RestResponseFiles_RestRequestFiles', 'F') IS NOT NULL 
    ALTER TABLE dbo.RestResponseFiles DROP CONSTRAINT FK_RestResponseFiles_RestRequestFiles;

IF OBJECT_ID('dbo.FK_RestExecutionGroupDetails_RestRequestFiles', 'F') IS NOT NULL 
    ALTER TABLE dbo.RestExecutionGroupDetails DROP CONSTRAINT FK_RestExecutionGroupDetails_RestRequestFiles;

IF OBJECT_ID('dbo.FK_RestExecutionGroupDetails_RestExecutionGroups', 'F') IS NOT NULL 
    ALTER TABLE dbo.RestExecutionGroupDetails DROP CONSTRAINT FK_RestExecutionGroupDetails_RestExecutionGroups;

IF OBJECT_ID('dbo.FK_RestExecutionGroups_RestApplications', 'F') IS NOT NULL 
    ALTER TABLE dbo.RestExecutionGroups DROP CONSTRAINT FK_RestExecutionGroups_RestApplications;

IF OBJECT_ID('dbo.FK_RestRequestFiles_RestEndpoints', 'F') IS NOT NULL 
    ALTER TABLE dbo.RestRequestFiles DROP CONSTRAINT FK_RestRequestFiles_RestEndpoints;

IF OBJECT_ID('dbo.FK_RestRequestFiles_RestApplications', 'F') IS NOT NULL 
    ALTER TABLE dbo.RestRequestFiles DROP CONSTRAINT FK_RestRequestFiles_RestApplications;

IF OBJECT_ID('dbo.FK_RestOpenApiSync_RestApplications', 'F') IS NOT NULL 
    ALTER TABLE dbo.RestOpenApiSync DROP CONSTRAINT FK_RestOpenApiSync_RestApplications;

IF OBJECT_ID('dbo.FK_RestEndpoints_RestApplications', 'F') IS NOT NULL 
    ALTER TABLE dbo.RestEndpoints DROP CONSTRAINT FK_RestEndpoints_RestApplications;

IF OBJECT_ID('dbo.FK_RestAppAuth_RestApplications', 'F') IS NOT NULL 
    ALTER TABLE dbo.RestAppAuth DROP CONSTRAINT FK_RestAppAuth_RestApplications;

-- ----------------------------------------------------------------------------
-- 2. DROP SOAP FOREIGN KEYS
-- ----------------------------------------------------------------------------
IF OBJECT_ID('dbo.FK_SoapResponseFiles_SoapRequestFiles', 'F') IS NOT NULL 
    ALTER TABLE dbo.SoapResponseFiles DROP CONSTRAINT FK_SoapResponseFiles_SoapRequestFiles;

IF OBJECT_ID('dbo.FK_SoapExecutionGroupDetails_SoapRequestFiles', 'F') IS NOT NULL 
    ALTER TABLE dbo.SoapExecutionGroupDetails DROP CONSTRAINT FK_SoapExecutionGroupDetails_SoapRequestFiles;

IF OBJECT_ID('dbo.FK_SoapExecutionGroupDetails_SoapExecutionGroups', 'F') IS NOT NULL 
    ALTER TABLE dbo.SoapExecutionGroupDetails DROP CONSTRAINT FK_SoapExecutionGroupDetails_SoapExecutionGroups;

IF OBJECT_ID('dbo.FK_SoapExecutionGroups_SoapApplications', 'F') IS NOT NULL 
    ALTER TABLE dbo.SoapExecutionGroups DROP CONSTRAINT FK_SoapExecutionGroups_SoapApplications;

IF OBJECT_ID('dbo.FK_SoapRequestFiles_SoapOperations', 'F') IS NOT NULL 
    ALTER TABLE dbo.SoapRequestFiles DROP CONSTRAINT FK_SoapRequestFiles_SoapOperations;

IF OBJECT_ID('dbo.FK_SoapRequestFiles_SoapApplications', 'F') IS NOT NULL 
    ALTER TABLE dbo.SoapRequestFiles DROP CONSTRAINT FK_SoapRequestFiles_SoapApplications;

IF OBJECT_ID('dbo.FK_SoapWsdlSync_SoapApplications', 'F') IS NOT NULL 
    ALTER TABLE dbo.SoapWsdlSync DROP CONSTRAINT FK_SoapWsdlSync_SoapApplications;

IF OBJECT_ID('dbo.FK_SoapOperations_SoapApplications', 'F') IS NOT NULL 
    ALTER TABLE dbo.SoapOperations DROP CONSTRAINT FK_SoapOperations_SoapApplications;

IF OBJECT_ID('dbo.FK_SoapAppAuth_SoapApplications', 'F') IS NOT NULL 
    ALTER TABLE dbo.SoapAppAuth DROP CONSTRAINT FK_SoapAppAuth_SoapApplications;

-- ----------------------------------------------------------------------------
-- 3. DROP RULES & CORE FOREIGN KEYS
-- ----------------------------------------------------------------------------
IF OBJECT_ID('dbo.FK_RuleSubMenus_RuleGroups', 'F') IS NOT NULL 
    ALTER TABLE dbo.RuleSubMenus DROP CONSTRAINT FK_RuleSubMenus_RuleGroups;

IF OBJECT_ID('dbo.FK_UserRoleMappings_Roles', 'F') IS NOT NULL 
    ALTER TABLE dbo.UserRoleMappings DROP CONSTRAINT FK_UserRoleMappings_Roles;

IF OBJECT_ID('dbo.FK_UserRoleMappings_Users', 'F') IS NOT NULL 
    ALTER TABLE dbo.UserRoleMappings DROP CONSTRAINT FK_UserRoleMappings_Users;

-- ----------------------------------------------------------------------------
-- 4. DROP REST TABLES
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS dbo.RestResponseFiles;
DROP TABLE IF EXISTS dbo.RestExecutionGroupDetails;
DROP TABLE IF EXISTS dbo.RestExecutionGroups;
DROP TABLE IF EXISTS dbo.RestRequestFiles;
DROP TABLE IF EXISTS dbo.RestOpenApiSync;
DROP TABLE IF EXISTS dbo.RestEndpoints;
DROP TABLE IF EXISTS dbo.RestAppAuth;
DROP TABLE IF EXISTS dbo.RestApplications;

-- ----------------------------------------------------------------------------
-- 5. DROP SOAP TABLES
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS dbo.SoapResponseFiles;
DROP TABLE IF EXISTS dbo.SoapExecutionGroupDetails;
DROP TABLE IF EXISTS dbo.SoapExecutionGroups;
DROP TABLE IF EXISTS dbo.SoapRequestFiles;
DROP TABLE IF EXISTS dbo.SoapWsdlSync;
DROP TABLE IF EXISTS dbo.SoapOperations;
DROP TABLE IF EXISTS dbo.SoapAppAuth;
DROP TABLE IF EXISTS dbo.SoapApplications;

-- ----------------------------------------------------------------------------
-- 6. DROP RULES & CORE TABLES
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS dbo.RuleSubMenus;
DROP TABLE IF EXISTS dbo.RuleGroups;
DROP TABLE IF EXISTS dbo.SystemSettings;
DROP TABLE IF EXISTS dbo.UserRoleMappings;
DROP TABLE IF EXISTS dbo.Roles;
DROP TABLE IF EXISTS dbo.Users;
GO