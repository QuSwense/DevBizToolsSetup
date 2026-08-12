-- This file contains SQL statements that will be executed after the build script.
/*
--------------------------------------------------------------------------------------
 Master Post-Deployment Script
--------------------------------------------------------------------------------------
 This script appends and executes child scripts in sequential order.
--------------------------------------------------------------------------------------
*/

-- 1. Master / Lookup tables (no foreign keys)
-- 1. Master / Lookup tables
:r ".\SeedData\01_Languages.sql"
:r ".\SeedData\02_Users.sql"
:r ".\SeedData\03_LocalizationCategories.sql"
:r ".\SeedData\04_AuthTypes.sql"
