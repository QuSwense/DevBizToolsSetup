/*
    RunSeeds.sql - Execute all seed scripts in the correct FK-dependent order

    This script inserts seed data into all reference/lookup tables in the proper
    order to respect foreign key constraints. It handles the circular FK dependency
    between Users and Roles by inserting the SYSTEM user with NULL references first,
    then updating after Roles are seeded.

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
-- Step 1: Seed Users (SYSTEM user with NULL RoleId/CreatedBy to break circular FK)
-- ============================================
PRINT 'Step 1/9: Seeding Users...';
:r ../Seeds/UsersSeed.sql
PRINT '  Users seed completed.';
PRINT '';

-- ============================================
-- Step 2: Seed Roles (references Users.UserId via CreatedBy)
-- ============================================
PRINT 'Step 2/9: Seeding Roles...';
:r ../Seeds/RolesSeed.sql
PRINT '  Roles seed completed.';
PRINT '';

-- ============================================
-- Step 3: Update SYSTEM user's RoleId to Developer
--          (circular FK resolved after Roles exist)
-- ============================================
PRINT 'Step 3/9: Updating SYSTEM user RoleId...';
UPDATE [dbo].[Users]
SET [RoleId] = (SELECT [Id] FROM [dbo].[Roles] WHERE [Name] = N'Developer')
WHERE [UserId] = 'SYSTEM'
  AND [RoleId] IS NULL;
PRINT '  SYSTEM user RoleId updated.';
PRINT '';

-- ============================================
-- Step 4: Seed ResourcePermissions (references Users.UserId via CreatedBy)
-- ============================================
PRINT 'Step 4/9: Seeding ResourcePermissions...';
:r ../Seeds/ResourcePermissionsSeed.sql
PRINT '  ResourcePermissions seed completed.';
PRINT '';

-- ============================================
-- Step 5: Seed UIPages (references ResourcePermissions.Id and Users.UserId)
-- ============================================
PRINT 'Step 5/9: Seeding UIPages...';
:r ../Seeds/UIPagesSeed.sql
PRINT '  UIPages seed completed.';
PRINT '';

-- ============================================
-- Step 6: Seed UIActions (references UIPages.Id, ResourcePermissions.Id, Users.UserId)
-- ============================================
PRINT 'Step 6/9: Seeding UIActions...';
:r ../Seeds/UIActionsSeed.sql
PRINT '  UIActions seed completed.';
PRINT '';

-- ============================================
-- Step 7: Seed PermissionToUIPageMapping (references ResourcePermissions.Id, UIPages.Id)
-- ============================================
PRINT 'Step 7/9: Seeding PermissionToUIPageMapping...';
:r ../Seeds/PermissionToUIPageMappingSeed.sql
PRINT '  PermissionToUIPageMapping seed completed.';
PRINT '';

-- ============================================
-- Step 8: Seed RolePermissions (references Roles.Id, ResourcePermissions.Id)
-- ============================================
PRINT 'Step 8/9: Seeding RolePermissions...';
:r ../Seeds/RolePermissionsSeed.sql
PRINT '  RolePermissions seed completed.';
PRINT '';

-- ============================================
-- Step 9: Seed GlobalSettings (references Users.UserId via CreatedBy)
-- ============================================
PRINT 'Step 9/9: Seeding GlobalSettings...';
:r ../Seeds/GlobalSettingsSeed.sql
PRINT '  GlobalSettings seed completed.';
PRINT '';

PRINT '========================================';
PRINT '  All seed data inserted successfully!';
PRINT '========================================';
GO