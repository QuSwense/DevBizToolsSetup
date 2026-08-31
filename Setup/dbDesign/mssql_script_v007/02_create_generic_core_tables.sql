-- ============================================================================
-- SCRIPT 2: GENERIC CORE, USER & RULES MANAGEMENT TABLES
-- Target Engine: Microsoft SQL Server
-- Includes: PKs, FKs, Indexes, Constraints, and Extended Properties
-- ============================================================================

SET NOCOUNT ON;

-- 1. USERS TABLE
CREATE TABLE dbo.Users (
    UserId INT IDENTITY(1,1) NOT NULL,
    Username NVARCHAR(100) NOT NULL,
    Email NVARCHAR(255) NOT NULL,
    PasswordHash NVARCHAR(500) NOT NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_Users_IsActive DEFAULT (1),
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT (SYSDATETIME()),
    UpdatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_Users PRIMARY KEY CLUSTERED (UserId ASC),
    CONSTRAINT UQ_Users_Username UNIQUE (Username),
    CONSTRAINT UQ_Users_Email UNIQUE (Email)
);

-- 2. ROLES TABLE
CREATE TABLE dbo.Roles (
    RoleId INT IDENTITY(1,1) NOT NULL,
    RoleName NVARCHAR(50) NOT NULL,
    Description NVARCHAR(255) NULL,
    CONSTRAINT PK_Roles PRIMARY KEY CLUSTERED (RoleId ASC),
    CONSTRAINT UQ_Roles_RoleName UNIQUE (RoleName)
);

-- 3. USER ROLE MAPPINGS TABLE
CREATE TABLE dbo.UserRoleMappings (
    UserRoleId INT IDENTITY(1,1) NOT NULL,
    UserId INT NOT NULL,
    RoleId INT NOT NULL,
    AssignedAt DATETIME2(7) NOT NULL CONSTRAINT DF_UserRoleMappings_AssignedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_UserRoleMappings PRIMARY KEY CLUSTERED (UserRoleId ASC),
    CONSTRAINT FK_UserRoleMappings_Users FOREIGN KEY (UserId) REFERENCES dbo.Users(UserId) ON DELETE CASCADE,
    CONSTRAINT FK_UserRoleMappings_Roles FOREIGN KEY (RoleId) REFERENCES dbo.Roles(RoleId) ON DELETE CASCADE
);

-- 4. SYSTEM SETTINGS TABLE
CREATE TABLE dbo.SystemSettings (
    SettingId INT IDENTITY(1,1) NOT NULL,
    SettingKey NVARCHAR(100) NOT NULL,
    SettingValue NVARCHAR(MAX) NULL,
    Description NVARCHAR(255) NULL,
    UpdatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_SystemSettings_UpdatedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_SystemSettings PRIMARY KEY CLUSTERED (SettingId ASC),
    CONSTRAINT UQ_SystemSettings_SettingKey UNIQUE (SettingKey)
);

-- 5. RULE GROUPS TABLE (Main Menu: Rules Management)
CREATE TABLE dbo.RuleGroups (
    RuleGroupId INT IDENTITY(1,1) NOT NULL,
    GroupCode NVARCHAR(50) NOT NULL,
    GroupName NVARCHAR(100) NOT NULL,
    Description NVARCHAR(255) NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_RuleGroups_IsActive DEFAULT (1),
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_RuleGroups_CreatedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_RuleGroups PRIMARY KEY CLUSTERED (RuleGroupId ASC),
    CONSTRAINT UQ_RuleGroups_GroupCode UNIQUE (GroupCode)
);

-- 6. RULE SUB MENUS TABLE (Sub-menus under Rules Management)
CREATE TABLE dbo.RuleSubMenus (
    RuleSubMenuId INT IDENTITY(1,1) NOT NULL,
    RuleGroupId INT NOT NULL,
    SubMenuName NVARCHAR(100) NOT NULL,
    RoutePath NVARCHAR(255) NOT NULL,
    DisplayOrder INT NOT NULL CONSTRAINT DF_RuleSubMenus_DisplayOrder DEFAULT (0),
    IsActive BIT NOT NULL CONSTRAINT DF_RuleSubMenus_IsActive DEFAULT (1),
    CONSTRAINT PK_RuleSubMenus PRIMARY KEY CLUSTERED (RuleSubMenuId ASC),
    CONSTRAINT FK_RuleSubMenus_RuleGroups FOREIGN KEY (RuleGroupId) REFERENCES dbo.RuleGroups(RuleGroupId) ON DELETE CASCADE
);

-- ----------------------------------------------------------------------------
-- INDEXES
-- ----------------------------------------------------------------------------
CREATE NONCLUSTERED INDEX IX_UserRoleMappings_UserId ON dbo.UserRoleMappings(UserId);
CREATE NONCLUSTERED INDEX IX_UserRoleMappings_RoleId ON dbo.UserRoleMappings(RoleId);
CREATE NONCLUSTERED INDEX IX_RuleSubMenus_RuleGroupId ON dbo.RuleSubMenus(RuleGroupId);

-- ----------------------------------------------------------------------------
-- EXTENDED PROPERTIES (DOCUMENTATION)
-- ----------------------------------------------------------------------------
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Stores user account information.', @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'Users';
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Top-level rule categories under Rules Management main menu.', @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'RuleGroups';
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Sub-menus for managing individual rule definitions under Rules Management.', @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'RuleSubMenus';
GO