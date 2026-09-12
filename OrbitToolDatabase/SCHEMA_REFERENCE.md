# OrbitTool Database — Schema Reference

> **Purpose**: Comprehensive reference for AI models and developers to understand the OrbitTool database schema, foreign key dependencies, seed data, and execution scripts without re-scanning individual files.
>
> **Last updated**: 2026-09-12
> **Total tables**: 48

---

## Table of Contents

1. [Schema Overview](#1-schema-overview)
2. [Table Inventory (A–Z)](#2-table-inventory-a-z)
3. [Foreign Key Dependency Graph](#3-foreign-key-dependency-graph)
4. [Circular FK Dependency: Users ↔ Roles](#4-circular-fk-dependency-users--roles)
5. [Seed Data](#5-seed-data)
   - [5.1 Seed Execution Order](#51-seed-execution-order)
   - [5.2 Seed Scripts Detail](#52-seed-scripts-detail)
6. [Execution Scripts](#6-execution-scripts)
   - [6.1 OrbitTool_SQLCMD.sh — Menu](#61-orbittool_sqlcmdsh--menu)
   - [6.2 RunSeeds.sql — Insert Seed Data](#62-runseedssql--insert-seed-data)
   - [6.3 ClearSeeds.sql — Clear All Data](#63-clearseedssql--clear-all-data)
   - [6.4 OrbitTool_ResetAndRecreate.sql — Full Reset](#64-orbittool_resetandrecreatesql--full-reset)
   - [6.5 ApplyColumnDescriptions.sql — Column Metadata](#65-applycolumndescriptionssql--column-metadata)
7. [Common Patterns Across Tables](#7-common-patterns-across-tables)
8. [Key Design Decisions](#8-key-design-decisions)

---

## 1. Schema Overview

The OrbitTool database is an SSDT (SQL Server Data Tools) project (`OrbitTool.sqlproj`) with 48 tables organized into these functional domains:

| Domain | Tables | Description |
|--------|--------|-------------|
| **Identity & Access** | 8 | Users, Roles, ResourcePermissions, RolePermissions, UserPermissions, PermissionToUIPageMapping, UIPages, UIActions |
| **Service Applications** | 8 | ServiceApplications, ServiceAppAuthentications, ServiceAppPermissions, ServiceOperations, ServiceOperationSchemas, ServiceDefinitionSyncs, SoapNamespaces |
| **Request/Response Files** | 10 | ServiceRequestFiles, ServiceResponseFiles, ServiceRequestFileEmbeddings, ServiceResponseFileEmbeddings, ServiceRequestIndexingStatus, ServiceResponseIndexingStatus, BinaryEmbeddingsStore, ServiceRequestFilesPermissions, DirectExecutionAudit, DirectExecutionAuditResponseFileLinks |
| **Rule Engine** | 5 | RuleSets, RuleContextObjects, RuleSetContextObjectLinks, RuleSetsPermissions, RuleExecutionLogs |
| **Test Management** | 8 | ServiceTestSuites, ServiceTestCases, ServiceTestSuitesPermissions, ServiceTestCasesPermissions, ServiceTestSuiteTestCaseLinks, ServiceTestCaseRuleSetLinks, ServiceTestSuiteExecutionAudits, ServiceTestSuiteExecutionAuditTestCaseLinks |
| **File Indexing (EAV)** | 9 | IndexingXmlFileElements, IndexingXmlFileElementSearch, IndexingXmlFileElementMappings, IndexingJsonFileElements, IndexingJsonFileElementSearch, IndexingJsonFileElementMappings, IndexingPdfFileElements, IndexingPdfFileElementSearch, IndexingPdfFileElementMappings |
| **Configuration** | 2 | GlobalSettings, UserSettings |
| **Audit/Activity** | 1 | UserActivities |

---

## 2. Table Inventory (A–Z)

### 2.1 Identity & Access Domain

#### `Users`
| Column | Type | Constraints |
|--------|------|-------------|
| UserId | NVARCHAR(20) | **PK** |
| Email | NVARCHAR(250) | NOT NULL, UNIQUE |
| Department | NVARCHAR(100) | NULL |
| FirstName | NVARCHAR(100) | NULL |
| LastName | NVARCHAR(100) | NULL |
| RoleId | INT | NULL, FK → Roles(Id) ON DELETE SET NULL |
| IsActive | BIT | DEFAULT 1 |
| CreatedAt | DATETIME | DEFAULT GETDATE() |
| CreatedBy | NVARCHAR(20) | NULL, FK → Users(UserId) |
| LastUpdatedAt | DATETIME | NULL |
| LastUpdatedBy | NVARCHAR(20) | NULL, FK → Users(UserId) |

**Notes**: PK is a natural key (AD User ID). Circular FK with Roles (see §4).

#### `Roles`
| Column | Type | Constraints |
|--------|------|-------------|
| Id | INT | **PK**, IDENTITY |
| PublicId | UNIQUEIDENTIFIER | UNIQUE, DEFAULT NEWID() |
| Name | NVARCHAR(50) | NOT NULL, UNIQUE |
| Description | NVARCHAR(500) | NULL |
| IsSystemRole | BIT | DEFAULT 0 |
| IsActive | BIT | DEFAULT 1 |
| CreatedAt | DATETIME | DEFAULT GETDATE() |
| CreatedBy | NVARCHAR(20) | NOT NULL, FK → Users(UserId) |
| LastUpdatedAt | DATETIME | NULL |
| LastUpdatedBy | NVARCHAR(20) | NULL, FK → Users(UserId) |

**Seeded roles**: `Developer`, `Admin`, `Viewer` (all `IsSystemRole = 1`).

#### `ResourcePermissions`
| Column | Type | Constraints |
|--------|------|-------------|
| Id | BIGINT | **PK**, IDENTITY |
| PublicId | UNIQUEIDENTIFIER | UNIQUE, DEFAULT NEWID() |
| PermissionKey | NVARCHAR(MAX) | NULL, UNIQUE (format: `resource:action`) |
| CreatedAt | DATETIME | DEFAULT GETDATE() |
| CreatedBy | NVARCHAR(20) | NOT NULL, FK → Users(UserId) |
| LastUpdatedAt | DATETIME | NULL |
| LastUpdatedBy | NVARCHAR(20) | NULL, FK → Users(UserId) |

**Permission key format**: `{resource}:{action}` — e.g., `serviceapplication:read`, `ruleset:write`, `settings:admin`. UNIQUE constraint added to prevent duplicate permission keys.

#### `RolePermissions`
| Column | Type | Constraints |
|--------|------|-------------|
| Id | BIGINT | **PK**, IDENTITY |
| PublicId | UNIQUEIDENTIFIER | UNIQUE, DEFAULT NEWID() |
| RoleId | INT | NOT NULL, FK → Roles(Id) ON DELETE CASCADE |
| ResourcePermissionId | BIGINT | NOT NULL, FK → ResourcePermissions(Id) ON DELETE CASCADE |
| IsGranted | BIT | DEFAULT 1 |
| IsActive | BIT | DEFAULT 1 |
| CreatedAt | DATETIME | DEFAULT GETDATE() |
| CreatedBy | NVARCHAR(20) | NOT NULL, FK → Users(UserId) |
| LastUpdatedAt | DATETIME | NULL |
| LastUpdatedBy | NVARCHAR(20) | NULL, FK → Users(UserId) |

**Unique**: `(RoleId, ResourcePermissionId)`.

#### `UserPermissions`
| Column | Type | Constraints |
|--------|------|-------------|
| Id | BIGINT | **PK**, IDENTITY |
| PublicId | UNIQUEIDENTIFIER | UNIQUE, DEFAULT NEWID() |
| UserId | NVARCHAR(20) | NOT NULL, FK → Users(UserId) |
| ResourcePermissionId | BIGINT | NOT NULL, FK → ResourcePermissions(Id) |
| IsGranted | BIT | DEFAULT 1 |
| IsActive | BIT | DEFAULT 1 |
| CreatedAt | DATETIME | DEFAULT GETDATE() |
| CreatedBy | NVARCHAR(20) | NOT NULL, FK → Users(UserId) |
| LastUpdatedAt | DATETIME | NULL |
| LastUpdatedBy | NVARCHAR(20) | NULL, FK → Users(UserId) |

**Unique**: `(UserId, ResourcePermissionId)`. Overrides role-level permissions.

#### `UIPages`
| Column | Type | Constraints |
|--------|------|-------------|
| Id | INT | **PK**, IDENTITY |
| PublicId | UNIQUEIDENTIFIER | UNIQUE, DEFAULT NEWID() |
| ParentId | INT | NULL, FK → UIPages(Id) (self-referencing hierarchy) |
| Name | NVARCHAR(100) | NOT NULL, UNIQUE |
| ResourcePermissionsId | BIGINT | NOT NULL, FK → ResourcePermissions(Id) |
| FeatureFlag | NVARCHAR(100) | NULL |
| IsActive | BIT | DEFAULT 1 |
| IsVisibleInNav | BIT | DEFAULT 1 |
| CreatedAt | DATETIME | DEFAULT GETDATE() |
| CreatedBy | NVARCHAR(20) | NOT NULL, FK → Users(UserId) |
| LastUpdatedAt | DATETIME | NULL |
| LastUpdatedBy | NVARCHAR(20) | NULL, FK → Users(UserId) |

**Structure**: Hierarchical via `ParentId`. Root pages: Dashboard, ServiceApplications, RuleSets, ServiceRequestFiles, TestManagement, Reports, Settings, Administration.

#### `UIActions`
| Column | Type | Constraints |
|--------|------|-------------|
| Id | INT | **PK**, IDENTITY |
| PublicId | UNIQUEIDENTIFIER | UNIQUE, DEFAULT NEWID() |
| PageId | INT | NOT NULL, FK → UIPages(Id) ON DELETE CASCADE |
| ActionName | NVARCHAR(50) | NOT NULL |
| DisplayName | NVARCHAR(100) | NOT NULL |
| ResourcePermissionsId | BIGINT | NOT NULL, FK → ResourcePermissions(Id) |
| ActionType | NVARCHAR(20) | DEFAULT 'Button' |
| UiElementId | NVARCHAR(100) | NULL |
| IsActive | BIT | DEFAULT 1 |
| CreatedAt | DATETIME | DEFAULT GETDATE() |
| CreatedBy | NVARCHAR(20) | NOT NULL, FK → Users(UserId) |
| LastUpdatedAt | DATETIME | NULL |
| LastUpdatedBy | NVARCHAR(20) | NULL, FK → Users(UserId) |

**Unique**: `(PageId, ActionName)`.

#### `PermissionToUIPageMapping`
| Column | Type | Constraints |
|--------|------|-------------|
| Id | INT | **PK**, IDENTITY |
| PublicId | UNIQUEIDENTIFIER | UNIQUE, DEFAULT NEWID() |
| ResourcePermissionId | BIGINT | NOT NULL, FK → ResourcePermissions(Id) ON DELETE CASCADE |
| UIPageId | INT | NOT NULL, FK → UIPages(Id) ON DELETE CASCADE |
| AccessType | NVARCHAR(20) | DEFAULT 'View' (View/Edit/Full) |
| IsActive | BIT | DEFAULT 1 |
| CreatedAt | DATETIME | DEFAULT GETDATE() |
| CreatedBy | NVARCHAR(20) | NOT NULL, FK → Users(UserId) |
| LastUpdatedAt | DATETIME | NULL |
| LastUpdatedBy | NVARCHAR(20) | NULL, FK → Users(UserId) |

**Unique**: `(ResourcePermissionId, UIPageId)`.

---

### 2.2 Service Applications Domain

#### `ServiceApplications`
| Column | Type | Constraints |
|--------|------|-------------|
| Id | INT | **PK**, IDENTITY |
| PublicId | UNIQUEIDENTIFIER | UNIQUE, DEFAULT NEWID() |
| ServiceType | VARCHAR(10) | NOT NULL, CHECK (SOAP/REST) |
| ServiceAppAuthenticationId | BIGINT | NULL, FK → ServiceAppAuthentications(Id) |
| Name | NVARCHAR(200) | NOT NULL |
| BaseUrl | NVARCHAR(500) | NOT NULL, CHECK (http:// or https://) |
| DefinitionType | VARCHAR(20) | NULL (WSDL/Swagger/OpenAPI) |
| DefinitionRelativeUrl | NVARCHAR(250) | NULL |
| HealthcheckRelativeUrl | NVARCHAR(250) | NULL |
| Description | NVARCHAR(MAX) | NULL |
| IsActive | BIT | DEFAULT 1 |
| RecordVersion | VARCHAR(50) | NOT NULL, DEFAULT fn_CalculateVersion(NULL), CHECK (YY.QQ.NN) |
| CreatedAt | DATETIME | DEFAULT GETDATE() |
| CreatedBy | NVARCHAR(20) | NOT NULL, FK → Users(UserId) |
| LastUpdatedAt | DATETIME | NULL |
| LastUpdatedBy | NVARCHAR(20) | NULL, FK → Users(UserId) |

**Unique**: `(Name, RecordVersion)` and `(PublicId, RecordVersion)`.

#### `ServiceAppAuthentications`
| Column | Type | Constraints |
|--------|------|-------------|
| Id | BIGINT | **PK**, IDENTITY |
| PublicId | UNIQUEIDENTIFIER | UNIQUE, DEFAULT NEWID() |
| Name | NVARCHAR(200) | NOT NULL, UNIQUE |
| AuthenticationType | VARCHAR(50) | NOT NULL, CHECK (Basic/NTLM/APIKey/OAuth2/Bearer/Custom) |
| EncryptionAlgorithmType | VARCHAR(50) | NULL, CHECK (AES-GCM/RSA/None) |
| EncryptedJson | NVARCHAR(MAX) | NOT NULL, CHECK (ISJSON) |
| IsActive | BIT | DEFAULT 1 |
| RecordVersion | VARCHAR(50) | NOT NULL, DEFAULT fn_CalculateVersion(NULL), CHECK (YY.QQ.NN) |
| CreatedAt | DATETIME | DEFAULT GETDATE() |
| CreatedBy | NVARCHAR(20) | NOT NULL, FK → Users(UserId) |
| LastUpdatedAt | DATETIME | NULL |
| LastUpdatedBy | NVARCHAR(20) | NULL, FK → Users(UserId) |

**Note**: UNIQUE constraint simplified from `(Name, PublicId)` to `(Name)` — `PublicId` is already independently unique.

#### `ServiceAppPermissions`
| Column | Type | Constraints |
|--------|------|-------------|
| Id | INT | **PK**, IDENTITY |
| PublicId | UNIQUEIDENTIFIER | UNIQUE, DEFAULT NEWID() |
| ServiceApplicationId | INT | NOT NULL, FK → ServiceApplications(Id) ON DELETE CASCADE |
| UserId | NVARCHAR(20) | NULL, FK → Users(UserId) ON DELETE CASCADE |
| RoleId | INT | NULL, FK → Roles(Id) ON DELETE CASCADE |
| ResourcePermissionId | BIGINT | NOT NULL, FK → ResourcePermissions(Id) |
| IsGranted | BIT | DEFAULT 1 |
| IsActive | BIT | DEFAULT 1 |
| CreatedAt | DATETIME | DEFAULT GETDATE() |
| CreatedBy | NVARCHAR(20) | NOT NULL, FK → Users(UserId) |
| LastUpdatedAt | DATETIME | NULL |
| LastUpdatedBy | NVARCHAR(20) | NULL, FK → Users(UserId) |

**Constraints**: Exactly one of `UserId` or `RoleId` must be provided (not both, not neither).

#### `ServiceOperations`
| Column | Type | Constraints |
|--------|------|-------------|
| Id | INT | **PK**, IDENTITY |
| PublicId | UNIQUEIDENTIFIER | UNIQUE, DEFAULT NEWID() |
| ServiceApplicationId | INT | NOT NULL, FK → ServiceApplications(Id) ON DELETE CASCADE |
| OperationName | NVARCHAR(200) | NOT NULL |
| EndpointOrAction | NVARCHAR(500) | NULL |
| HttpMethod | VARCHAR(10) | NULL, CHECK (GET/POST/PUT/DELETE/PATCH/HEAD/OPTIONS) |
| Description | NVARCHAR(MAX) | NULL |
| IsActive | BIT | DEFAULT 1 |
| RecordVersion | VARCHAR(50) | NOT NULL, DEFAULT fn_CalculateVersion(NULL), CHECK (YY.QQ.NN) |
| CreatedAt | DATETIME | DEFAULT GETDATE() |
| CreatedBy | NVARCHAR(20) | NOT NULL, FK → Users(UserId) |
| LastUpdatedAt | DATETIME | NULL |
| LastUpdatedBy | NVARCHAR(20) | NULL, FK → Users(UserId) |

#### `ServiceOperationSchemas`
| Column | Type | Constraints |
|--------|------|-------------|
| Id | INT | **PK**, IDENTITY |
| PublicId | UNIQUEIDENTIFIER | UNIQUE, DEFAULT NEWID() |
| ServiceOperationId | INT | NOT NULL, FK → ServiceOperations(Id) ON DELETE CASCADE |
| InputRootElementName | NVARCHAR(200) | NULL |
| OutputRootElementName | NVARCHAR(200) | NULL |
| TargetNamespace | NVARCHAR(500) | NULL |
| CompressedContent | VARBINARY(MAX) | NOT NULL |
| UncompressedSizeBytes | INT | NULL |
| CompressionAlgorithmType | VARCHAR(50) | NULL, CHECK (Zstandard/Brotli/Gzip/none) |
| ContentHash | VARCHAR(64) | NULL, CHECK (64 hex chars) |
| RecordVersion | VARCHAR(50) | NOT NULL, DEFAULT fn_CalculateVersion(NULL), CHECK (YY.QQ.NN) |
| CreatedAt | DATETIME | DEFAULT GETDATE() |
| CreatedBy | NVARCHAR(20) | NOT NULL, FK → Users(UserId) |
| LastUpdatedAt | DATETIME | NULL |
| LastUpdatedBy | NVARCHAR(20) | NULL, FK → Users(UserId) |

#### `ServiceDefinitionSyncs`
| Column | Type | Constraints |
|--------|------|-------------|
| Id | INT | **PK**, IDENTITY |
| PublicId | UNIQUEIDENTIFIER | UNIQUE, DEFAULT NEWID() |
| ServiceApplicationId | INT | NOT NULL, FK → ServiceApplications(Id) ON DELETE CASCADE |
| DefinitionUrl | NVARCHAR(500) | NULL, CHECK (http:// or https://) |
| CompressedContent | VARBINARY(MAX) | NOT NULL |
| UncompressedSizeBytes | INT | NULL |
| CompressionAlgorithmType | VARCHAR(50) | NULL, CHECK (Zstandard/Brotli/Gzip/none) |
| ContentHash | VARCHAR(64) | NULL, CHECK (64 hex chars) |
| RecordVersion | VARCHAR(50) | NOT NULL, DEFAULT fn_CalculateVersion(NULL), CHECK (YY.QQ.NN) |
| CreatedAt | DATETIME | DEFAULT GETDATE() |
| CreatedBy | NVARCHAR(20) | NOT NULL, FK → Users(UserId) |
| LastUpdatedAt | DATETIME | NULL |
| LastUpdatedBy | NVARCHAR(20) | NULL, FK → Users(UserId) |

**Note**: `DefinitionUrl` column was added to align with the CHECK constraint. The redundant `IX_ServiceDefinitionSyncs_ServiceApplicationId` unique constraint was removed (subset of `UQ_ServiceDefinitionSyncs_ServiceApplicationId_RecordVersion`).

#### `SoapNamespaces`
| Column | Type | Constraints |
|--------|------|-------------|
| Id | INT | **PK**, IDENTITY |
| PublicId | UNIQUEIDENTIFIER | UNIQUE, DEFAULT NEWID() |
| ServiceOperationSchemaId | INT | NOT NULL, FK → ServiceOperationSchemas(Id) ON DELETE CASCADE |
| CompressedContent | VARBINARY(MAX) | NOT NULL |
| UncompressedSizeBytes | INT | NULL |
| CompressionAlgorithmType | VARCHAR(50) | NULL, CHECK (Zstandard/Brotli/Gzip/none) |
| ContentHash | VARCHAR(64) | NULL, CHECK (64 hex chars) |
| RecordVersion | VARCHAR(50) | NOT NULL, DEFAULT fn_CalculateVersion(NULL), CHECK (YY.QQ.NN) |
| CreatedAt | DATETIME | DEFAULT GETDATE() |
| CreatedBy | NVARCHAR(20) | NULL |
| LastUpdatedAt | DATETIME | NULL |
| LastUpdatedBy | NVARCHAR(20) | NULL |

---

### 2.3 Request/Response Files Domain

#### `ServiceRequestFiles`
| Column | Type | Constraints |
|--------|------|-------------|
| Id | INT | **PK**, IDENTITY |
| PublicId | UNIQUEIDENTIFIER | UNIQUE, DEFAULT NEWID() |
| ServiceOperationId | INT | NOT NULL, FK → ServiceOperations(Id) ON DELETE CASCADE |
| FileFormat | VARCHAR(10) | NULL, CHECK (XML/JSON/PDF/BINARY) |
| Name | NVARCHAR(250) | NOT NULL |
| IsBaseSnapshot | BIT | DEFAULT 1 |
| ParentBaseId | INT | NULL, FK → ServiceRequestFiles(Id) |
| ParentDeltaId | INT | NULL, FK → ServiceRequestFiles(Id) |
| DeltaDepth | INT | DEFAULT 0 |
| CompressedData | VARBINARY(MAX) | NOT NULL |
| UncompressedSizeBytes | INT | NULL |
| CompressionAlgorithmType | VARCHAR(50) | NULL, CHECK (Zstandard/Brotli/Gzip/none) |
| ContentHash | VARCHAR(64) | NULL, CHECK (64 hex chars) |
| RecordVersion | VARCHAR(50) | NOT NULL, DEFAULT fn_CalculateVersion(NULL), CHECK (YY.QQ.NN) |
| IsActive | BIT | DEFAULT 1 |
| CreatedAt | DATETIME | DEFAULT GETDATE() |
| CreatedBy | NVARCHAR(20) | NOT NULL, FK → Users(UserId) |
| LastUpdatedAt | DATETIME | NULL |
| LastUpdatedBy | NVARCHAR(20) | NULL, FK → Users(UserId) |

**Delta chain**: Self-referencing via `ParentBaseId` and `ParentDeltaId` for versioned file storage. Self-referencing FK constraints added for delta chain integrity.

#### `ServiceResponseFiles`
| Column | Type | Constraints |
|--------|------|-------------|
| Id | INT | **PK**, IDENTITY |
| PublicId | UNIQUEIDENTIFIER | UNIQUE, DEFAULT NEWID() |
| ServiceRequestFileId | INT | NOT NULL, FK → ServiceRequestFiles(Id) ON DELETE CASCADE |
| FileFormat | VARCHAR(10) | NULL, CHECK (XML/JSON/PDF/BINARY) |
| Name | NVARCHAR(250) | NOT NULL |
| IsBaseSnapshot | BIT | DEFAULT 1 |
| ParentBaseId | INT | NULL, FK → ServiceResponseFiles(Id) |
| ParentDeltaId | INT | NULL, FK → ServiceResponseFiles(Id) |
| DeltaDepth | INT | DEFAULT 0 |
| CompressedData | VARBINARY(MAX) | NOT NULL |
| UncompressedSizeBytes | INT | NULL |
| CompressionAlgorithmType | VARCHAR(50) | NULL, CHECK (Zstandard/Brotli/Gzip/none) |
| ContentHash | VARCHAR(64) | NULL, CHECK (64 hex chars) |
| RecordVersion | VARCHAR(50) | NOT NULL, DEFAULT fn_CalculateVersion(NULL), CHECK (YY.QQ.NN) |
| IsActive | BIT | DEFAULT 1 |
| CreatedAt | DATETIME | DEFAULT GETDATE() |
| CreatedBy | NVARCHAR(20) | NOT NULL, FK → Users(UserId) |
| LastUpdatedAt | DATETIME | NULL |
| LastUpdatedBy | NVARCHAR(20) | NULL, FK → Users(UserId) |

**Delta chain**: Same structure as `ServiceRequestFiles` with self-referencing FKs for delta chain integrity. FK to `ServiceRequestFiles(Id)` has `ON DELETE CASCADE`.

#### `ServiceRequestFileEmbeddings` / `ServiceResponseFileEmbeddings`
Link files to deduplicated binary content in `BinaryEmbeddingsStore`. Each has `PublicId` (UNIQUE, DEFAULT NEWID()), `FileHash` (SHA-256), and `BinaryEmbeddingsStoreId`.

#### `BinaryEmbeddingsStore`
Content-addressable binary storage keyed by SHA-256 hash. Single-instance deduplication enforced via `UQ_BinaryEmbeddingsStore_FileHash`. Has `PublicId` (UNIQUE, DEFAULT NEWID()) for UI-safe external references.

#### `ServiceRequestIndexingStatus` / `ServiceResponseIndexingStatus`
One-to-one status tracking for background element indexing. Status values: `Pending`, `Processing`, `Completed`, `Failed`.

#### `ServiceRequestFilesPermissions`
Same pattern as `ServiceAppPermissions` — grants permissions to users or roles for specific files.

#### `DirectExecutionAudit`
Logs direct (non-test-suite) executions. Has `PublicId` (UNIQUE, DEFAULT NEWID()). Links to response files via `DirectExecutionAuditResponseFileLinks`.

---

### 2.4 Rule Engine Domain

#### `RuleContextObjects`
| Column | Type | Constraints |
|--------|------|-------------|
| Id | INT | **PK**, IDENTITY |
| PublicId | UNIQUEIDENTIFIER | UNIQUE, DEFAULT NEWID() |
| ContextName | NVARCHAR(100) | NOT NULL, UNIQUE |
| RuleTypeId | NVARCHAR(255) | NOT NULL (assembly-qualified .NET type) |
| Description | NVARCHAR(500) | NULL |
| IsActive | BIT | DEFAULT 1 |
| CreatedDate | DATETIME | DEFAULT GETDATE() |
| CreatedBy | NVARCHAR(20) | NOT NULL, FK → Users(UserId) |
| LastUpdatedDate | DATETIME | NULL |
| LastUpdatedBy | NVARCHAR(20) | NULL, FK → Users(UserId) |

#### `RuleSets`
| Column | Type | Constraints |
|--------|------|-------------|
| Id | INT | **PK**, IDENTITY |
| PublicId | UNIQUEIDENTIFIER | UNIQUE, DEFAULT NEWID() |
| WorkflowName | NVARCHAR(255) | NOT NULL, UNIQUE |
| RuleContent | NVARCHAR(MAX) | NOT NULL, CHECK (ISJSON) |
| OutputTypeId | INT | NOT NULL, FK → RuleContextObjects(Id) |
| IsActive | BIT | DEFAULT 1 |
| Description | NVARCHAR(500) | NULL |
| RecordVersion | VARCHAR(50) | NOT NULL, DEFAULT fn_CalculateVersion(NULL), CHECK (YY.QQ.NN) |
| CreatedAt | DATETIME | DEFAULT GETDATE() |
| CreatedBy | NVARCHAR(20) | NOT NULL, FK → Users(UserId) |
| LastUpdatedAt | DATETIME | NULL |
| LastUpdatedBy | NVARCHAR(20) | NULL, FK → Users(UserId) |

#### `RuleSetContextObjectLinks`
Many-to-many link between `RuleSets` and `RuleContextObjects`. Has `PublicId` (UNIQUE, DEFAULT NEWID()).

#### `RuleSetsPermissions`
Same pattern as `ServiceAppPermissions` — grants permissions to users or roles for specific rule sets.

#### `RuleExecutionLogs`
Logs rule execution with compressed input/output, success status, error messages, and timing. Has `PublicId` (UNIQUE, DEFAULT NEWID()).

---

### 2.5 Test Management Domain

#### `ServiceTestSuites`
| Column | Type | Constraints |
|--------|------|-------------|
| Id | INT | **PK**, IDENTITY |
| PublicId | UNIQUEIDENTIFIER | UNIQUE, DEFAULT NEWID() |
| Name | NVARCHAR(200) | NOT NULL, UNIQUE |
| Description | NVARCHAR(MAX) | NULL |
| IsActive | BIT | DEFAULT 1 |
| RecordVersion | VARCHAR(50) | NOT NULL, DEFAULT fn_CalculateVersion(NULL), CHECK (YY.QQ.NN) |
| CreatedAt | DATETIME | DEFAULT GETDATE() |
| CreatedBy | NVARCHAR(20) | NOT NULL, FK → Users(UserId) |
| LastUpdatedAt | DATETIME | NULL |
| LastUpdatedBy | NVARCHAR(20) | NULL, FK → Users(UserId) |

#### `ServiceTestCases`
| Column | Type | Constraints |
|--------|------|-------------|
| Id | INT | **PK**, IDENTITY |
| PublicId | UNIQUEIDENTIFIER | UNIQUE, DEFAULT NEWID() |
| Name | NVARCHAR(200) | NOT NULL, UNIQUE |
| ServiceRequestFileId | INT | NULL, FK → ServiceRequestFiles(Id) |
| IsActive | BIT | DEFAULT 1 |
| RecordVersion | VARCHAR(50) | NOT NULL, DEFAULT fn_CalculateVersion(NULL), CHECK (YY.QQ.NN) |
| CreatedAt | DATETIME | DEFAULT GETDATE() |
| CreatedBy | NVARCHAR(20) | NOT NULL, FK → Users(UserId) |
| LastUpdatedAt | DATETIME | NULL |
| LastUpdatedBy | NVARCHAR(20) | NULL, FK → Users(UserId) |

#### `ServiceTestSuitesPermissions` / `ServiceTestCasesPermissions`
Same pattern as `ServiceAppPermissions`.

#### `ServiceTestSuiteTestCaseLinks`
Links test suites to test cases with `ExecutionOrder`. Has `PublicId` (UNIQUE, DEFAULT NEWID()).

#### `ServiceTestCaseRuleSetLinks`
Many-to-many link between test cases and rule sets. Has `PublicId` (UNIQUE, DEFAULT NEWID()).

#### `ServiceTestSuiteExecutionAudits`
Logs test suite executions. Has `PublicId` (UNIQUE, DEFAULT NEWID()). Links to individual test case results via `ServiceTestSuiteExecutionAuditTestCaseLinks`.

---

### 2.6 File Indexing Domain (EAV Pattern)

Three parallel sets of tables for XML, JSON, and PDF indexing:

- **`Indexing{Xml|Json|Pdf}FileElements`** — Unique element definitions (name + path/type)
- **`Indexing{Xml|Json|Pdf}FileElementSearch`** — Element values (denormalized for search)
- **`Indexing{Xml|Json|Pdf}FileElementMappings`** — Maps elements to request/response files

---

### 2.7 Configuration Domain

#### `GlobalSettings`
| Column | Type | Constraints |
|--------|------|-------------|
| Id | INT | **PK**, IDENTITY |
| PublicId | UNIQUEIDENTIFIER | UNIQUE, DEFAULT NEWID() |
| Category | NVARCHAR(50) | DEFAULT 'General' |
| SettingKey | NVARCHAR(100) | NOT NULL, UNIQUE |
| SettingValue | NVARCHAR(MAX) | NOT NULL |
| DataType | VARCHAR(20) | DEFAULT 'String', CHECK (String/Integer/Decimal/Boolean/Json/Xml/DateTime) |
| Description | NVARCHAR(500) | NULL |
| IsUserOverridable | BIT | DEFAULT 0 |
| IsActive | BIT | DEFAULT 1 |
| CreatedAt | DATETIME | DEFAULT GETDATE() |
| CreatedBy | NVARCHAR(20) | NOT NULL, FK → Users(UserId) |
| LastUpdatedAt | DATETIME | NULL |
| LastUpdatedBy | NVARCHAR(20) | NULL, FK → Users(UserId) |

#### `UserSettings`
Per-user overrides of global settings. FK to `GlobalSettings(Id)` ON DELETE SET NULL.

---

### 2.8 Audit Domain

#### `UserActivities`
| Column | Type | Constraints |
|--------|------|-------------|
| Id | BIGINT | **PK**, IDENTITY |
| PublicId | UNIQUEIDENTIFIER | UNIQUE, DEFAULT NEWID() |
| UserId | NVARCHAR(20) | NOT NULL, FK → Users(UserId) ON DELETE CASCADE |
| ActivityType | NVARCHAR(100) | NOT NULL (e.g., Login, FeatureUsage) |
| ActionType | NVARCHAR(50) | NULL (e.g., Click, View, Edit) |
| FeatureActivitiesJson | NVARCHAR(MAX) | NULL, CHECK (ISJSON) |
| Timestamp | DATETIME | DEFAULT GETDATE() |

---

## 3. Foreign Key Dependency Graph

### 3.1 Core Reference Tables (Seed Data)

```
Users ──┐
         ├── Roles (CreatedBy)
         ├── ResourcePermissions (CreatedBy)
         ├── UIPages (CreatedBy)
         ├── UIActions (CreatedBy)
         ├── PermissionToUIPageMapping (CreatedBy)
         ├── RolePermissions (CreatedBy)
         ├── GlobalSettings (CreatedBy)
         ├── UserSettings (UserId)
         ├── UserPermissions (UserId, CreatedBy)
         └── UserActivities (UserId)

Roles ──┐
        ├── RolePermissions (RoleId)
        ├── ServiceAppPermissions (RoleId)
        ├── ServiceRequestFilesPermissions (RoleId)
        ├── ServiceTestSuitesPermissions (RoleId)
        ├── ServiceTestCasesPermissions (RoleId)
        └── RuleSetsPermissions (RoleId)

ResourcePermissions ──┐
                      ├── UIPages (ResourcePermissionsId)
                      ├── UIActions (ResourcePermissionsId)
                      ├── PermissionToUIPageMapping (ResourcePermissionId)
                      ├── RolePermissions (ResourcePermissionId)
                      ├── UserPermissions (ResourcePermissionId)
                      ├── ServiceAppPermissions (ResourcePermissionId)
                      ├── ServiceRequestFilesPermissions (ResourcePermissionId)
                      ├── ServiceTestSuitesPermissions (ResourcePermissionId)
                      ├── ServiceTestCasesPermissions (ResourcePermissionId)
                      └── RuleSetsPermissions (ResourcePermissionId)

UIPages ──┐
          ├── UIActions (PageId)
          ├── PermissionToUIPageMapping (UIPageId)
          └── self (ParentId)
```

### 3.2 Application Data Dependency Chain

```
ServiceApplications
  ├── ServiceAppAuthentications (ServiceAppAuthenticationId)
  ├── ServiceAppPermissions (ServiceApplicationId)
  ├── ServiceOperations (ServiceApplicationId) [ON DELETE CASCADE]
  │     ├── ServiceOperationSchemas (ServiceOperationId) [ON DELETE CASCADE]
  │     │     └── SoapNamespaces (ServiceOperationSchemaId)
  │     └── ServiceRequestFiles (ServiceOperationId) [ON DELETE CASCADE]
  │           ├── ServiceResponseFiles (ServiceRequestFileId) [ON DELETE CASCADE]
  │           │     └── self (ParentBaseId, ParentDeltaId)
  │           ├── ServiceRequestFileEmbeddings (ServiceRequestFileId)
  │           ├── ServiceRequestIndexingStatus (ServiceRequestFileId)
  │           ├── ServiceRequestFilesPermissions (ServiceRequestFileId)
  │           ├── DirectExecutionAuditResponseFileLinks (ServiceRequestFileId)
  │           └── ServiceTestCases (ServiceRequestFileId)
  ├── ServiceDefinitionSyncs (ServiceApplicationId)
  └── ServiceOperations (ServiceApplicationId)

ServiceResponseFiles
  ├── self (ParentBaseId, ParentDeltaId)
  ├── ServiceResponseFileEmbeddings (ServiceResponseFileId)
  ├── ServiceResponseIndexingStatus (ServiceResponseFileId)
  ├── DirectExecutionAuditResponseFileLinks (ServiceResponseFileId)
  └── ServiceTestSuiteExecutionAuditTestCaseLinks (ServiceResponseFileId)

BinaryEmbeddingsStore
  ├── ServiceRequestFileEmbeddings (BinaryEmbeddingsStoreId)
  └── ServiceResponseFileEmbeddings (BinaryEmbeddingsStoreId)

RuleContextObjects
  └── RuleSets (OutputTypeId)
        ├── RuleSetContextObjectLinks (RuleSetId)
        ├── RuleSetsPermissions (RuleSetId)
        ├── RuleExecutionLogs (RuleSetId)
        └── ServiceTestCaseRuleSetLinks (RuleSetId)

ServiceTestSuites
  ├── ServiceTestSuitesPermissions (ServiceTestSuiteId)
  ├── ServiceTestSuiteTestCaseLinks (ServiceTestSuiteId)
  └── ServiceTestSuiteExecutionAudits (ServiceTestSuiteId)
        └── ServiceTestSuiteExecutionAuditTestCaseLinks (ServiceTestSuiteExecutionAuditId)

ServiceTestCases
  ├── ServiceTestCasesPermissions (ServiceTestCaseId)
  ├── ServiceTestSuiteTestCaseLinks (ServiceTestCaseId)
  ├── ServiceTestCaseRuleSetLinks (ServiceTestCaseId)
  └── ServiceTestSuiteExecutionAuditTestCaseLinks (ServiceTestCaseId)

DirectExecutionAudit
  └── DirectExecutionAuditResponseFileLinks (DirectExecutionAuditId)
```

### 3.3 Indexing Tables Dependency

```
IndexingXmlFileElements
  └── IndexingXmlFileElementSearch (IndexingXmlFileElementId)
        └── IndexingXmlFileElementMappings (IndexingXmlFileElementSearchId)
              ├── ServiceRequestFiles (RequestFileId) — CHECK: exactly one of RequestFileId/ResponseFileId
              └── ServiceResponseFiles (ResponseFileId) — CHECK: exactly one of RequestFileId/ResponseFileId

[Same pattern for JSON and PDF]

Note: `IndexingPdfFileElementMappings` uses `BinaryEmbeddingsStoreId` (NOT NULL) instead of RequestFileId/ResponseFileId.
```

---

## 4. Circular FK Dependency: Users ↔ Roles

There is a **circular foreign key dependency** between `Users` and `Roles`:

```
Users.RoleId    → Roles(Id)     [ON DELETE SET NULL]
Roles.CreatedBy → Users(UserId)
```

This means neither table can be created with both FKs active before the other exists. The SSDT project handles this by:

1. Creating `Users` **without** `FK_Users_Roles_RoleId`
2. Creating `Roles` with `FK_Roles_Users_CreatedBy`
3. Adding `FK_Users_Roles_RoleId` via `ALTER TABLE` after both exist

For seed data, the `RunSeeds.sql` script handles it by:

1. Inserting the `SYSTEM` user with `RoleId = NULL` and `CreatedBy = NULL`
2. Inserting the three system roles (`Developer`, `Admin`, `Viewer`) referencing `SYSTEM` as `CreatedBy`
3. Updating the `SYSTEM` user's `RoleId` to point to the `Developer` role

---

## 5. Seed Data

### 5.1 Seed Execution Order

The `RunSeeds.sql` script executes seeds in this exact order (9 steps):

| Step | Seed Script | Tables Populated | FK Dependencies Satisfied |
|------|-------------|-----------------|---------------------------|
| 1 | `UsersSeed.sql` | Users | None (SYSTEM inserted with NULL refs) |
| 2 | `RolesSeed.sql` | Roles | Users (CreatedBy → SYSTEM) |
| 3 | *(inline UPDATE)* | Users.RoleId | Roles (Developer role exists) |
| 4 | `ResourcePermissionsSeed.sql` | ResourcePermissions | Users (CreatedBy → SYSTEM) |
| 5 | `UIPagesSeed.sql` | UIPages | ResourcePermissions, Users |
| 6 | `UIActionsSeed.sql` | UIActions | UIPages, ResourcePermissions, Users |
| 7 | `PermissionToUIPageMappingSeed.sql` | PermissionToUIPageMapping | ResourcePermissions, UIPages |
| 8 | `RolePermissionsSeed.sql` | RolePermissions | Roles, ResourcePermissions |
| 9 | `GlobalSettingsSeed.sql` | GlobalSettings | Users (CreatedBy → SYSTEM) |

### 5.2 Seed Scripts Detail

#### `UsersSeed.sql`
Inserts 2 users idempotently:
- `SYSTEM` — system account, `RoleId = NULL` (updated in step 3), `CreatedBy = NULL`
- `test_soap_user1` — test user, `RoleId = Admin`, `CreatedBy = SYSTEM`

#### `RolesSeed.sql`
Inserts 3 system roles idempotently:
- `Developer` — full access including settings
- `Admin` — full access to main resources (excludes settings/system)
- `Viewer` — read-only access

#### `ResourcePermissionsSeed.sql`
Inserts 55 permission keys across these resource groups:
- `dashboard:view`
- `serviceapplication:*` (read, write, delete, execute, admin, share, test, configure)
- `ruleset:*` (read, write, delete, execute, admin, share, publish, version)
- `servicerequestfile:*` (read, write, delete, execute, admin, share, download, upload)
- `servicetestcase:*` (read, write, delete, execute, admin, share, run, schedule)
- `servicetestsuite:*` (read, write, delete, execute, admin, share, run, schedule)
- `settings:*` (read, write, admin)
- `user:*` (read, write, delete, admin)
- `role:*` (read, write, delete, admin)
- `permission:*` (read, write, admin)
- `report:*` (read, generate, export)
- `audit:*` (read, export)
- `system:*` (monitor, backup, restore)

#### `UIPagesSeed.sql`
Inserts 38 pages in a hierarchical structure:
- **Root (8)**: Dashboard, ServiceApplications, RuleSets, ServiceRequestFiles, TestManagement, Reports, Settings, Administration
- **ServiceApplications children (5)**: List, Create, Edit, Share, Test
- **RuleSets children (7)**: List, Create, Edit, Test, Share, Publish, Version
- **ServiceRequestFiles children (6)**: List, Upload, Download, Edit, Share, Execute
- **TestManagement children (10)**: TestSuites, TestCases, TestExecution, TestResults, TestSuiteCreate, TestSuiteEdit, TestSuiteShare, TestCaseCreate, TestCaseEdit, TestCaseShare
- **Reports children (3)**: TestReports, AuditReports, SystemReports
- **Settings children (4)**: GeneralSettings, SecuritySettings, IntegrationSettings, NotificationSettings
- **Administration children (6)**: UserManagement, RoleManagement, PermissionManagement, SystemHealth, AuditLogs, SystemBackup

Each page resolves its `ResourcePermissionsId` via a subquery on `PermissionKey`.

#### `UIActionsSeed.sql`
Inserts 42 UI actions linked to specific pages, each with a resolved `ResourcePermissionsId`.

#### `PermissionToUIPageMappingSeed.sql`
Joins `ResourcePermissions` to `UIPages` via `ResourcePermissionsId` and derives `AccessType` from the permission key suffix (`:admin` → Full, `:write` → Edit, `:read` → View).

#### `RolePermissionsSeed.sql`
Grants permissions to the three system roles:
- **Developer**: ALL permissions (all resource groups)
- **Admin**: All except `settings:*` and `system:*`
- **Viewer**: Read-only (`dashboard:view`, `*:read` for serviceapp/ruleset/servicerequestfile/servicetestcase/servicetestsuite/report/audit)

#### `GlobalSettingsSeed.sql`
Inserts 25 settings across 7 categories (all idempotent):

| Category | Settings |
|----------|----------|
| General | Application.Name, Application.Version, Application.DefaultCulture, Application.Timezone |
| UI | UI.Sidebar.DefaultState, UI.Theme.Default, UI.Pagination.PageSize, UI.Pagination.MaxPageSize, UI.DateFormat, UI.DateTimeFormat |
| Authentication | Auth.SessionTimeoutMinutes, Auth.MaxLoginAttempts, Auth.LockoutDurationMinutes, Auth.PasswordMinLength, Auth.RequireMfa |
| Service | Service.RequestTimeoutSeconds, Service.MaxFileSizeMb, Service.CompressionAlgorithm, Service.RuleEngine.MaxExecutionTimeMs |
| Indexing | Indexing.Enabled, Indexing.BatchSize, Indexing.MaxConcurrentJobs |
| Logging | Logging.RetentionDays, Logging.AuditLevel |
| Monitoring | Monitoring.HealthCheckIntervalSeconds |
| Feature | Feature.EnableAdminModule, Feature.EnableFileIndexing, Feature.EnableTestScheduling |

---

## 6. Execution Scripts

All scripts live in `OrbitToolDatabase/scripts/`.

### 6.1 `OrbitTool_SQLCMD.sh` — Menu

A bash script providing an interactive menu with 6 options:

| # | Option | Scripts Executed |
|---|--------|-----------------|
| 1 | Reset and Recreate Schema | `OrbitTool_ResetAndRecreate.sql` |
| 2 | Reset + Recreate + Column Descriptions | `OrbitTool_ResetAndRecreate.sql` + `ApplyColumnDescriptions.sql` |
| 3 | Apply Column Descriptions only | `ApplyColumnDescriptions.sql` |
| 4 | Insert Seed Data | `RunSeeds.sql` |
| 5 | Clear All Table Data | `ClearSeeds.sql` |
| 6 | Clear Data + Re-insert Seeds | `ClearSeeds.sql` + `RunSeeds.sql` |

**Configuration**: Server `localhost,1433`, user `sa`, password from `SQLCMDPASSWORD` env var (default `root@1234`).

### 6.2 `RunSeeds.sql` — Insert Seed Data

Uses `:r` (sqlcmd include) directives to execute seed scripts in FK-safe order (see §5.1). Handles the circular FK dependency between Users and Roles.

### 6.3 `ClearSeeds.sql` — Clear All Data

Deletes all rows from all 48 tables in reverse FK dependency order (most-dependent first). The deletion order is:

1. Indexing tables (9): XmlFileElementSearch/Mappings/Elements, JsonFileElementSearch/Mappings/Elements, PdfFileElementSearch/Mappings/Elements
2. DirectExecutionAuditResponseFileLinks, DirectExecutionAudit
3. ServiceTestSuiteExecutionAuditTestCaseLinks, ServiceTestSuiteExecutionAudits, ServiceTestSuiteTestCaseLinks, ServiceTestCaseRuleSetLinks
4. ServiceTestSuitesPermissions, ServiceTestCasesPermissions
5. ServiceTestSuites, ServiceTestCases
6. ServiceResponseIndexingStatus, ServiceResponseFileEmbeddings, ServiceResponseFiles
7. ServiceRequestIndexingStatus, ServiceRequestFileEmbeddings, ServiceRequestFilesPermissions, ServiceRequestFiles
8. BinaryEmbeddingsStore
9. SoapNamespaces, ServiceOperationSchemas, ServiceOperations, ServiceDefinitionSyncs
10. ServiceAppPermissions
11. ServiceApplications
12. ServiceAppAuthentications
13. RuleExecutionLogs, RuleSetContextObjectLinks, RuleSetsPermissions, RuleSets
14. UserSettings, UserActivities, UserPermissions
15. RolePermissions
16. PermissionToUIPageMapping
17. UIActions
18. UIPages
19. ResourcePermissions
20. GlobalSettings
21. RuleContextObjects
22. Roles
23. Users

### 6.4 `OrbitTool_ResetAndRecreate.sql` — Full Reset

Drops all FK constraints, views, stored procedures, tables (most-dependent first), full-text catalog, and `fn_CalculateVersion` function, then recreates everything from the SSDT project source files using `:r` include directives.

### 6.5 `ApplyColumnDescriptions.sql` — Column Metadata

Applies `MS_Description` extended properties to every column in every table using a cursor. Descriptions are generated from column name patterns (e.g., `Id` → "Unique identifier for this {table} record", `PermissionKey` → "Unique permission key in the form resource:action").

---

## 7. Common Patterns Across Tables

### 7.1 Audit Columns
Almost every table includes:
- `CreatedAt DATETIME DEFAULT GETDATE()`
- `CreatedBy NVARCHAR(20) NOT NULL` — FK → `Users(UserId)`
- `LastUpdatedAt DATETIME NULL`
- `LastUpdatedBy NVARCHAR(20) NULL` — FK → `Users(UserId)`

### 7.2 Public Identifier
Most tables have a `PublicId UNIQUEIDENTIFIER DEFAULT NEWID()` with a UNIQUE constraint — used for UI operations and external references without exposing identity values.

### 7.3 Record Versioning
Tables in the Service Applications, Rule Engine, and Test Management domains use:
- `RecordVersion VARCHAR(50) DEFAULT fn_CalculateVersion(NULL)` — format `YY.QQ.NN`
- CHECK constraint: `LIKE '[0-9][0-9].[0-9][0-9].[0-9][0-9]'`

### 7.4 Compression Pattern
Tables storing binary content use:
- `CompressedData VARBINARY(MAX)` or `CompressedContent VARBINARY(MAX)`
- `UncompressedSizeBytes INT`
- `CompressionAlgorithmType VARCHAR(50)` — CHECK (Zstandard/Brotli/Gzip/none)
- `ContentHash VARCHAR(64)` — CHECK (64 hex chars)

### 7.5 Permission Tables Pattern
Tables like `ServiceAppPermissions`, `ServiceRequestFilesPermissions`, `ServiceTestSuitesPermissions`, `ServiceTestCasesPermissions`, `RuleSetsPermissions` all follow the same pattern:
- FK to the resource table (ON DELETE CASCADE)
- `UserId NVARCHAR(20) NULL` and `RoleId INT NULL` — exactly one must be set
- `ResourcePermissionId BIGINT NOT NULL`
- `IsGranted BIT DEFAULT 1`
- CHECK constraints ensure exactly one of UserId/RoleId is provided

### 7.6 Indexing EAV Pattern
Three parallel sets of tables for XML, JSON, and PDF:
- **Elements table**: Stores unique element definitions (name + path/type)
- **Search table**: Stores element values, FK to Elements
- **Mappings table**: Maps search entries to request/response files

---

## 8. Key Design Decisions

1. **Natural PK for Users**: `UserId` is NVARCHAR(20) — the AD user ID — rather than an identity column, ensuring uniqueness across the organization.

2. **Circular FK resolution**: The Users ↔ Roles circular dependency is resolved at the SSDT project level by deferring the `Users.RoleId` FK creation, and at the seed level by inserting SYSTEM with NULL references then updating.

3. **Delta chain for files**: `ServiceRequestFiles` and `ServiceResponseFiles` support versioned storage via `IsBaseSnapshot`, `ParentBaseId`, `ParentDeltaId`, and `DeltaDepth` — enabling differential storage of file changes.

4. **Content-addressable storage**: `BinaryEmbeddingsStore` uses SHA-256 hashes for single-instance deduplication of binary content across all embeddings.

5. **Decoupled indexing status**: `ServiceRequestIndexingStatus` and `ServiceResponseIndexingStatus` are separate tables (not columns on the file tables) to avoid row-locking during high-frequency execution saves.

6. **Permission model**: Three-layer permission system — role-level (`RolePermissions`), user-level (`UserPermissions`), and resource-level (`ServiceAppPermissions` et al.) — with `IsGranted` allowing both grant and deny semantics.

7. **Optimistic concurrency**: `RecordVersion` with `fn_CalculateVersion()` provides YY.QQ.NN formatted versioning for conflict detection without locking.

8. **PublicId mandate**: Every table that is directly UI-exposed now has a `PublicId UNIQUEIDENTIFIER` column with a UNIQUE constraint. Exceptions: high-volume EAV indexing tables (9), 1:1 status tables (2), and `Users` (natural AD PK). See §C PublicId Audit for the full list.