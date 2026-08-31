-- ============================================================================
-- SCRIPT 4: REST SPECIFIC PARALLEL TABLES
-- Target Engine: Microsoft SQL Server
-- Includes: PKs, FKs, Indexes, Constraints, and Extended Properties
-- ============================================================================

SET NOCOUNT ON;

-- 1. REST APPLICATIONS TABLE
CREATE TABLE dbo.RestApplications (
    RestAppId INT IDENTITY(1,1) NOT NULL,
    AppName NVARCHAR(100) NOT NULL,
    OpenApiUrl NVARCHAR(500) NULL,
    BaseUrl NVARCHAR(500) NULL,
    Description NVARCHAR(500) NULL,
    IsActive BIT NOT NULL CONSTRAINT DF_RestApplications_IsActive DEFAULT (1),
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_RestApplications_CreatedAt DEFAULT (SYSDATETIME()),
    UpdatedAt DATETIME2(7) NULL,
    CONSTRAINT PK_RestApplications PRIMARY KEY CLUSTERED (RestAppId ASC),
    CONSTRAINT UQ_RestApplications_AppName UNIQUE (AppName)
);

-- 2. REST APP AUTHENTICATION TABLE
CREATE TABLE dbo.RestAppAuth (
    RestAuthId INT IDENTITY(1,1) NOT NULL,
    RestAppId INT NOT NULL,
    AuthType NVARCHAR(50) NOT NULL, -- e.g., Bearer, Basic, ApiKey, OAuth2
    Username NVARCHAR(100) NULL,
    PasswordHash NVARCHAR(500) NULL,
    ApiKeyName NVARCHAR(100) NULL,
    ApiKeyValue NVARCHAR(MAX) NULL,
    OAuthTokenUrl NVARCHAR(500) NULL,
    CONSTRAINT PK_RestAppAuth PRIMARY KEY CLUSTERED (RestAuthId ASC),
    CONSTRAINT FK_RestAppAuth_RestApplications FOREIGN KEY (RestAppId) REFERENCES dbo.RestApplications(RestAppId) ON DELETE CASCADE
);

-- 3. REST ENDPOINTS TABLE (Equivalent to SoapOperations)
CREATE TABLE dbo.RestEndpoints (
    RestEndpointId INT IDENTITY(1,1) NOT NULL,
    RestAppId INT NOT NULL,
    EndpointName NVARCHAR(150) NOT NULL,
    RoutePath NVARCHAR(300) NOT NULL,
    HttpMethod NVARCHAR(10) NOT NULL, -- GET, POST, PUT, DELETE, PATCH
    TagCategory NVARCHAR(100) NULL,
    RequestSampleBody NVARCHAR(MAX) NULL,
    CONSTRAINT PK_RestEndpoints PRIMARY KEY CLUSTERED (RestEndpointId ASC),
    CONSTRAINT FK_RestEndpoints_RestApplications FOREIGN KEY (RestAppId) REFERENCES dbo.RestApplications(RestAppId) ON DELETE CASCADE,
    CONSTRAINT CK_RestEndpoints_HttpMethod CHECK (HttpMethod IN ('GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS'))
);

-- 4. REST OPENAPI / SWAGGER SYNC HISTORY
CREATE TABLE dbo.RestOpenApiSync (
    SyncId INT IDENTITY(1,1) NOT NULL,
    RestAppId INT NOT NULL,
    SyncStatus NVARCHAR(50) NOT NULL,
    SyncDetails NVARCHAR(MAX) NULL,
    SyncedAt DATETIME2(7) NOT NULL CONSTRAINT DF_RestOpenApiSync_SyncedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_RestOpenApiSync PRIMARY KEY CLUSTERED (SyncId ASC),
    CONSTRAINT FK_RestOpenApiSync_RestApplications FOREIGN KEY (RestAppId) REFERENCES dbo.RestApplications(RestAppId) ON DELETE CASCADE
);

-- 5. REST REQUEST FILES TABLE
CREATE TABLE dbo.RestRequestFiles (
    RestRequestId INT IDENTITY(1,1) NOT NULL,
    RestAppId INT NOT NULL,
    RestEndpointId INT NOT NULL,
    RequestName NVARCHAR(150) NOT NULL,
    QueryParamsJson NVARCHAR(MAX) NULL,
    HeadersJson NVARCHAR(MAX) NULL,
    PayloadBody NVARCHAR(MAX) NULL,
    BodyContentType NVARCHAR(50) NULL CONSTRAINT DF_RestRequestFiles_BodyContentType DEFAULT ('application/json'),
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_RestRequestFiles_CreatedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_RestRequestFiles PRIMARY KEY CLUSTERED (RestRequestId ASC),
    CONSTRAINT FK_RestRequestFiles_RestApplications FOREIGN KEY (RestAppId) REFERENCES dbo.RestApplications(RestAppId),
    CONSTRAINT FK_RestRequestFiles_RestEndpoints FOREIGN KEY (RestEndpointId) REFERENCES dbo.RestEndpoints(RestEndpointId)
);

-- 6. REST EXECUTION GROUPS (Embedded Application Test Suites)
CREATE TABLE dbo.RestExecutionGroups (
    RestExecutionGroupId INT IDENTITY(1,1) NOT NULL,
    RestAppId INT NOT NULL,
    GroupName NVARCHAR(150) NOT NULL,
    Description NVARCHAR(255) NULL,
    ExecutionOrder INT NOT NULL CONSTRAINT DF_RestExecutionGroups_ExecutionOrder DEFAULT (1),
    IsActive BIT NOT NULL CONSTRAINT DF_RestExecutionGroups_IsActive DEFAULT (1),
    CreatedAt DATETIME2(7) NOT NULL CONSTRAINT DF_RestExecutionGroups_CreatedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_RestExecutionGroups PRIMARY KEY CLUSTERED (RestExecutionGroupId ASC),
    CONSTRAINT FK_RestExecutionGroups_RestApplications FOREIGN KEY (RestAppId) REFERENCES dbo.RestApplications(RestAppId) ON DELETE CASCADE
);

-- 7. REST EXECUTION GROUP DETAILS
CREATE TABLE dbo.RestExecutionGroupDetails (
    DetailId INT IDENTITY(1,1) NOT NULL,
    RestExecutionGroupId INT NOT NULL,
    RestRequestId INT NOT NULL,
    StepOrder INT NOT NULL,
    CONSTRAINT PK_RestExecutionGroupDetails PRIMARY KEY CLUSTERED (DetailId ASC),
    CONSTRAINT FK_RestExecutionGroupDetails_RestExecutionGroups FOREIGN KEY (RestExecutionGroupId) REFERENCES dbo.RestExecutionGroups(RestExecutionGroupId) ON DELETE CASCADE,
    CONSTRAINT FK_RestExecutionGroupDetails_RestRequestFiles FOREIGN KEY (RestRequestId) REFERENCES dbo.RestRequestFiles(RestRequestId)
);

-- 8. REST RESPONSE FILES TABLE
CREATE TABLE dbo.RestResponseFiles (
    RestResponseId INT IDENTITY(1,1) NOT NULL,
    RestRequestId INT NOT NULL,
    StatusCode INT NOT NULL,
    ResponseBody NVARCHAR(MAX) NULL,
    ResponseHeadersJson NVARCHAR(MAX) NULL,
    ExecutionTimeMs INT NOT NULL,
    ExecutedAt DATETIME2(7) NOT NULL CONSTRAINT DF_RestResponseFiles_ExecutedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_RestResponseFiles PRIMARY KEY CLUSTERED (RestResponseId ASC),
    CONSTRAINT FK_RestResponseFiles_RestRequestFiles FOREIGN KEY (RestRequestId) REFERENCES dbo.RestRequestFiles(RestRequestId) ON DELETE CASCADE
);

-- ----------------------------------------------------------------------------
-- INDEXES
-- ----------------------------------------------------------------------------
CREATE NONCLUSTERED INDEX IX_RestEndpoints_RestAppId ON dbo.RestEndpoints(RestAppId);
CREATE NONCLUSTERED INDEX IX_RestRequestFiles_RestAppId ON dbo.RestRequestFiles(RestAppId);
CREATE NONCLUSTERED INDEX IX_RestRequestFiles_RestEndpointId ON dbo.RestRequestFiles(RestEndpointId);
CREATE NONCLUSTERED INDEX IX_RestExecutionGroups_RestAppId ON dbo.RestExecutionGroups(RestAppId);

-- ----------------------------------------------------------------------------
-- EXTENDED PROPERTIES (DOCUMENTATION)
-- ----------------------------------------------------------------------------
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'REST Application master configuration.', @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'RestApplications';
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Stores endpoint configurations for REST services (Paths, HTTP Methods).', @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'RestEndpoints';
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Test suites / execution groups embedded strictly within REST applications.', @level0type=N'SCHEMA', @level0name=N'dbo', @level1type=N'TABLE', @level1name=N'RestExecutionGroups';
GO