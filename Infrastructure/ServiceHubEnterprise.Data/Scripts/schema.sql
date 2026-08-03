-- ============================================================================
-- ServiceHub Enterprise — SQLite Database Schema
-- Database-first approach: create this schema manually, then map C# entities
-- ============================================================================

-- ============================================================================
-- SOAP Feature
-- ============================================================================

CREATE TABLE IF NOT EXISTS SoapApps (
    Id              TEXT PRIMARY KEY,
    Name            TEXT NOT NULL,
    BaseUrl         TEXT NOT NULL,
    WsdlPath        TEXT NOT NULL DEFAULT '',
    Description     TEXT NOT NULL DEFAULT '',
    Status          TEXT NOT NULL DEFAULT 'enabled' CHECK(Status IN ('enabled','disabled')),
    CreatedBy       TEXT NOT NULL,
    UpdatedBy       TEXT,
    CreatedAt       TEXT NOT NULL,
    UpdatedAt       TEXT,
    ApisCount       INTEGER NOT NULL DEFAULT 0,
    AuthType        TEXT NOT NULL DEFAULT 'None' CHECK(AuthType IN ('None','Basic','ApiKey','Bearer','Ntlm')),
    AuthUsername    TEXT,
    AuthPassword    TEXT,
    AuthKeyName     TEXT,
    AuthKeyValue    TEXT,
    AuthToken       TEXT,
    AuthDomain      TEXT
);

CREATE TABLE IF NOT EXISTS SoapApis (
    Id          TEXT PRIMARY KEY,
    AppId       TEXT NOT NULL REFERENCES SoapApps(Id) ON DELETE CASCADE,
    Name        TEXT NOT NULL,
    Description TEXT NOT NULL DEFAULT ''
);

CREATE INDEX IF NOT EXISTS IX_SoapApis_AppId ON SoapApis(AppId);

CREATE TABLE IF NOT EXISTS SoapRequestFiles (
    Id          TEXT PRIMARY KEY,
    FileName    TEXT NOT NULL,
    AppName     TEXT NOT NULL,
    ApiPath     TEXT NOT NULL,
    Verb        TEXT NOT NULL DEFAULT 'POST',
    Description TEXT NOT NULL DEFAULT '',
    Status      TEXT NOT NULL DEFAULT 'active' CHECK(Status IN ('active','inactive')),
    CreatedBy   TEXT NOT NULL,
    CreatedAt   TEXT NOT NULL,
    UpdatedBy   TEXT,
    UpdatedAt   TEXT,
    Content     TEXT,
    TestCaseIds TEXT   -- JSON array of test case IDs
);

CREATE INDEX IF NOT EXISTS IX_SoapRequestFiles_AppName ON SoapRequestFiles(AppName);
CREATE INDEX IF NOT EXISTS IX_SoapRequestFiles_FileName ON SoapRequestFiles(FileName);

CREATE TABLE IF NOT EXISTS SoapFileVersions (
    Id            TEXT PRIMARY KEY,
    FileId        TEXT NOT NULL REFERENCES SoapRequestFiles(Id) ON DELETE CASCADE,
    FileName      TEXT NOT NULL,
    AppName       TEXT NOT NULL,
    Content       TEXT NOT NULL,
    SavedBy       TEXT NOT NULL,
    SavedAt       TEXT NOT NULL,
    VersionNumber INTEGER NOT NULL,
    Notes         TEXT
);

CREATE INDEX IF NOT EXISTS IX_SoapFileVersions_FileId ON SoapFileVersions(FileId);

CREATE TABLE IF NOT EXISTS SoapExecutionGroups (
    Id          TEXT PRIMARY KEY,
    StartedAt   TEXT NOT NULL,
    FinishedAt  TEXT,
    TriggeredBy TEXT NOT NULL,
    Status      TEXT NOT NULL DEFAULT 'running' CHECK(Status IN ('running','completed','failed','partial')),
    DurationMs  INTEGER
);

CREATE TABLE IF NOT EXISTS SoapExecutionFiles (
    Id               TEXT PRIMARY KEY,
    GroupId          TEXT NOT NULL REFERENCES SoapExecutionGroups(Id) ON DELETE CASCADE,
    FileName         TEXT NOT NULL,
    AppName          TEXT NOT NULL,
    Operation        TEXT NOT NULL,
    Status           TEXT NOT NULL DEFAULT 'queued' CHECK(Status IN ('queued','running','success','failed')),
    Stage            INTEGER NOT NULL DEFAULT 0,
    StagesCompleted  INTEGER NOT NULL DEFAULT 0,
    StagesTotal      INTEGER NOT NULL DEFAULT 7,
    RequestContent   TEXT,
    ResponseContent  TEXT,
    ResponseMimeType TEXT
);

CREATE INDEX IF NOT EXISTS IX_SoapExecutionFiles_GroupId ON SoapExecutionFiles(GroupId);

CREATE TABLE IF NOT EXISTS SoapExecutionLogs (
    Id              TEXT PRIMARY KEY,
    ExecutionFileId TEXT NOT NULL REFERENCES SoapExecutionFiles(Id) ON DELETE CASCADE,
    Timestamp       TEXT NOT NULL,
    Type            TEXT NOT NULL CHECK(Type IN ('info','warning','error','request','response','assertion')),
    Message         TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS IX_SoapExecutionLogs_FileId ON SoapExecutionLogs(ExecutionFileId);

CREATE TABLE IF NOT EXISTS SoapParsedFields (
    Id              TEXT PRIMARY KEY,
    ExecutionFileId TEXT NOT NULL REFERENCES SoapExecutionFiles(Id) ON DELETE CASCADE,
    Name            TEXT NOT NULL,
    Source          TEXT NOT NULL,
    Path            TEXT NOT NULL,
    Value           TEXT,
    IsEmbedded      INTEGER NOT NULL DEFAULT 0,
    DecodedPreview  TEXT
);

CREATE INDEX IF NOT EXISTS IX_SoapParsedFields_FileId ON SoapParsedFields(ExecutionFileId);

CREATE TABLE IF NOT EXISTS SoapExtractionResults (
    Id              TEXT PRIMARY KEY,
    ExecutionFileId TEXT NOT NULL REFERENCES SoapExecutionFiles(Id) ON DELETE CASCADE,
    ExtractorId     TEXT NOT NULL,
    Name            TEXT NOT NULL,
    Source          TEXT NOT NULL,
    Type            TEXT NOT NULL,
    Path            TEXT NOT NULL,
    Value           TEXT,
    Expected        TEXT,
    Passed          INTEGER
);

CREATE INDEX IF NOT EXISTS IX_SoapExtractionResults_FileId ON SoapExtractionResults(ExecutionFileId);

CREATE TABLE IF NOT EXISTS SoapTestCases (
    Id          TEXT PRIMARY KEY,
    Name        TEXT NOT NULL,
    Description TEXT NOT NULL DEFAULT '',
    AppName     TEXT NOT NULL,
    FileName    TEXT NOT NULL,
    Enabled     INTEGER NOT NULL DEFAULT 1,
    CreatedBy   TEXT NOT NULL,
    CreatedAt   TEXT NOT NULL,
    UpdatedBy   TEXT,
    UpdatedAt   TEXT
);

CREATE INDEX IF NOT EXISTS IX_SoapTestCases_AppFile ON SoapTestCases(AppName, FileName);

CREATE TABLE IF NOT EXISTS SoapExtractors (
    Id            TEXT PRIMARY KEY,
    TestCaseId    TEXT NOT NULL REFERENCES SoapTestCases(Id) ON DELETE CASCADE,
    Name          TEXT NOT NULL,
    Source        TEXT NOT NULL DEFAULT 'response' CHECK(Source IN ('request','response')),
    Type          TEXT NOT NULL DEFAULT 'xpath' CHECK(Type IN ('xpath','jsonpath','pdf')),
    Path          TEXT NOT NULL,
    ExpectedValue TEXT
);

CREATE INDEX IF NOT EXISTS IX_SoapExtractors_TestCaseId ON SoapExtractors(TestCaseId);

-- ============================================================================
-- REST Feature
-- ============================================================================

CREATE TABLE IF NOT EXISTS RestApps (
    Id          TEXT PRIMARY KEY,
    Name        TEXT NOT NULL,
    BaseUrl     TEXT NOT NULL,
    Description TEXT NOT NULL DEFAULT '',
    Status      TEXT NOT NULL DEFAULT 'enabled' CHECK(Status IN ('enabled','disabled')),
    CreatedBy   TEXT NOT NULL,
    CreatedAt   TEXT NOT NULL,
    UpdatedBy   TEXT,
    UpdatedAt   TEXT,
    ApisCount   INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS RestRequestFiles (
    Id          TEXT PRIMARY KEY,
    FileName    TEXT NOT NULL,
    AppName     TEXT NOT NULL,
    ApiPath     TEXT NOT NULL,
    Verb        TEXT NOT NULL DEFAULT 'GET',
    Description TEXT NOT NULL DEFAULT '',
    Status      TEXT NOT NULL DEFAULT 'active' CHECK(Status IN ('active','inactive')),
    CreatedBy   TEXT NOT NULL,
    CreatedAt   TEXT NOT NULL,
    UpdatedBy   TEXT,
    UpdatedAt   TEXT,
    Content     TEXT
);

CREATE INDEX IF NOT EXISTS IX_RestRequestFiles_AppName ON RestRequestFiles(AppName);

CREATE TABLE IF NOT EXISTS RestFileVersions (
    Id            TEXT PRIMARY KEY,
    FileId        TEXT NOT NULL REFERENCES RestRequestFiles(Id) ON DELETE CASCADE,
    FileName      TEXT NOT NULL,
    AppName       TEXT NOT NULL,
    Content       TEXT NOT NULL,
    SavedBy       TEXT NOT NULL,
    SavedAt       TEXT NOT NULL,
    VersionNumber INTEGER NOT NULL,
    Notes         TEXT
);

CREATE INDEX IF NOT EXISTS IX_RestFileVersions_FileId ON RestFileVersions(FileId);

-- ============================================================================
-- WSDL Feature
-- ============================================================================

CREATE TABLE IF NOT EXISTS WsdlRecords (
    Id              TEXT PRIMARY KEY,
    AppId           TEXT NOT NULL,
    AppName         TEXT NOT NULL,
    SourceType      TEXT NOT NULL CHECK(SourceType IN ('url','upload')),
    SourceUrl       TEXT NOT NULL,
    UploadedBy      TEXT NOT NULL,
    UploadedAt      TEXT NOT NULL,
    Status          TEXT NOT NULL DEFAULT 'synced' CHECK(Status IN ('synced','parsing','error')),
    WsdlContentKey  TEXT,
    VersionCount    INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS WsdlVersions (
    Id            TEXT PRIMARY KEY,
    SyncRecordId  TEXT NOT NULL REFERENCES WsdlRecords(Id) ON DELETE CASCADE,
    VersionNumber INTEGER NOT NULL,
    Label         TEXT NOT NULL,
    UploadedBy    TEXT NOT NULL,
    UploadedAt    TEXT NOT NULL,
    Status        TEXT NOT NULL DEFAULT 'active' CHECK(Status IN ('active','archived')),
    Notes         TEXT,
    Content       TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS IX_WsdlVersions_SyncRecordId ON WsdlVersions(SyncRecordId);

CREATE TABLE IF NOT EXISTS WsdlSyncHistory (
    Id           TEXT PRIMARY KEY,
    AppId        TEXT NOT NULL,
    AppName      TEXT NOT NULL,
    SyncRecordId TEXT NOT NULL,
    Date         TEXT NOT NULL,
    Status       TEXT NOT NULL,
    Details      TEXT
);

CREATE TABLE IF NOT EXISTS WsdlTemplates (
    Id                 TEXT PRIMARY KEY,
    Name               TEXT NOT NULL,
    Description        TEXT NOT NULL DEFAULT '',
    Content            TEXT NOT NULL,
    ExtendsTemplateId  TEXT,
    Variables          TEXT,     -- JSON array of variable names
    CreatedBy          TEXT NOT NULL,
    CreatedAt          TEXT NOT NULL,
    UpdatedAt          TEXT,
    UsageCount         INTEGER NOT NULL DEFAULT 0
);

-- ============================================================================
-- Dashboard Feature
-- ============================================================================

CREATE TABLE IF NOT EXISTS DashboardHealth (
    Name   TEXT PRIMARY KEY,
    Status TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS DashboardMetrics (
    Id    TEXT PRIMARY KEY,
    Name  TEXT NOT NULL UNIQUE,
    Value INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS Users (
    Name TEXT PRIMARY KEY,
    Role TEXT NOT NULL DEFAULT 'User'
);

CREATE TABLE IF NOT EXISTS UserActivity (
    Id        TEXT PRIMARY KEY,
    UserName  TEXT NOT NULL,
    Action    TEXT NOT NULL,
    Timestamp TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS IX_UserActivity_UserName ON UserActivity(UserName);

CREATE TABLE IF NOT EXISTS ServiceUptime (
    Id          TEXT PRIMARY KEY,
    ServiceName TEXT NOT NULL,
    Timestamp   TEXT NOT NULL,
    Status      TEXT NOT NULL CHECK(Status IN ('ok','down','degraded'))
);

CREATE INDEX IF NOT EXISTS IX_ServiceUptime_ServiceName ON ServiceUptime(ServiceName);

CREATE TABLE IF NOT EXISTS TestSuites (
    Name         TEXT PRIMARY KEY,
    TotalCases   INTEGER NOT NULL DEFAULT 0,
    PassingCases INTEGER NOT NULL DEFAULT 0,
    TotalFiles   INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS TestSuiteHistory (
    Id           TEXT PRIMARY KEY,
    SuiteName    TEXT NOT NULL,
    ExecutedAt   TEXT NOT NULL,
    Status       TEXT NOT NULL CHECK(Status IN ('passed','failed','running')),
    TotalCases   INTEGER NOT NULL DEFAULT 0,
    PassingCases INTEGER NOT NULL DEFAULT 0,
    DurationMs   INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS IX_TestSuiteHistory_SuiteName ON TestSuiteHistory(SuiteName);

CREATE TABLE IF NOT EXISTS RecentActivity (
    Id      INTEGER PRIMARY KEY AUTOINCREMENT,
    User    TEXT NOT NULL,
    Action  TEXT NOT NULL,
    TimeAgo TEXT NOT NULL
);

-- ============================================================================
-- File Management (Generic file versions)
-- ============================================================================

CREATE TABLE IF NOT EXISTS FileVersions (
    Id           TEXT PRIMARY KEY,
    SourceType   TEXT NOT NULL CHECK(SourceType IN ('soap','rest','wsdl','generic')),
    SourceId     TEXT NOT NULL,
    FileName     TEXT NOT NULL,
    Content      TEXT NOT NULL,
    SavedBy      TEXT NOT NULL,
    SavedAt      TEXT NOT NULL,
    VersionNumber INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS IX_FileVersions_Source ON FileVersions(SourceType, SourceId);