/*
    RunSeeds.sql - Execute all seed scripts in the correct FK-dependent order

    This script inserts seed data into all reference/lookup tables in the proper
    order to respect foreign key constraints.

    Usage:
        SQLCMDPASSWORD='...' sqlcmd -S localhost,1433 -U sa -C -d OrbitTool -b -i RunSeeds.sql
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
PRINT '  Starting seed data insertion';
PRINT '========================================';
PRINT '';

-- ============================================
-- Step 1: Seed Users (SYSTEM user, CreatedBy = NULL)
-- ============================================
PRINT 'Step 1/2: Seeding Users...';
:r ../Seeds/UsersSeed.sql
PRINT '  Users seed completed.';
PRINT '';

-- ============================================
-- Step 2: Seed GlobalSettings (references Users.UserId via CreatedBy)
-- ============================================
PRINT 'Step 2/2: Seeding GlobalSettings...';
:r ../Seeds/GlobalSettingsSeed.sql
PRINT '  GlobalSettings seed completed.';
PRINT '';

PRINT '========================================';
PRINT '  All seed data inserted successfully!';
PRINT '========================================';
GO