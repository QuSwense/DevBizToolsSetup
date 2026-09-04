# 02. Data Architecture

## Data source model

The application uses a single **MS SQL Server** relational database (`OrbitTool`) as its exclusive persistence backend. The data layer is organized into two complementary projects:

- **`Infrastructure/OrbitHub.Data/`** — .NET 10 class library containing linq2db entity mappings (`DataConnection` subclasses), stored procedure repositories, and view repositories.
- **`OrbitToolDatabase/`** — SSDT (SQL Server Data Tools) project defining the database schema: tables, views, stored procedures, functions, and seed data.

There is **no mock/JSON data store**. All feature data — applications, request files, execution history, templates, WSDL records, permissions, indexing, user activity — is persisted in MS SQL Server and accessed through the repository layer.

## Database server

The development environment uses a **Dockerized MS SQL Server** (Azure SQL Edge on ARM64/Apple Silicon) running on `localhost:1433`. The startup scripts are in `Setup/dockerscripts/` and the Docker image definition is in `Setup/docker-image/`.

Connection is configured via `ConnectionStrings:DefaultConnection` in the web host configuration files:

| File | Database | Server |
|------|----------|--------|
| `WebApp/OrbitHub.Web/appsettings.json` | `OrbitTool` | `localhost,1433` |
| `WebApp/OrbitHub.Web/appsettings.Development.json` | `OrbitTool` | `localhost,1433` |

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Data Source=localhost,1433;Initial Catalog=OrbitTool;User ID=sa;Password=...;Encrypt=True;TrustServerCertificate=True;Command Timeout=30"
  }
}
```

## ORM: linq2db (not Entity Framework Core)

All data access uses **[linq2db](https://linq2db.github.io/) v6.4.0** with the `Microsoft.Data.SqlClient` provider. The common pattern is:

1. A `DataConnection` subclass (called a "DbContext") defines table mappings via `ITable<T>` properties.
2. Repository classes receive the `DataConnection` via constructor injection.
3. Stored procedures are called with `QueryProcAsync<T>()`.
4. Views are queried with `QueryAsync<T>("SELECT * FROM [dbo].[v_Xxx]")`.
5. All results are wrapped in `RepositoryResult<T>` (Success/Fail pattern).

## DbContexts (linq2db DataConnection subclasses)

There are **11 focused DbContexts**, each in its own management subdirectory under `Infrastructure/OrbitHub.Data/`:

| # | DbContext | Subdirectory | Tables |
|---|-----------|-------------|--------|
| 1 | `CoreDbContext` | `CoreManagement/` | `GlobalSettings`, `UserSettings` |
| 2 | `UserDbContext` | `UserManagement/` | `Users`, `UserActivities` |
| 3 | `UiDbContext` | `UIManagement/` | `UiPages`, `UiActions`, `PermissionToUiPageMappings` |
| 4 | `RuleDbContext` | `RuleManagement/` | `RuleSets`, `RuleContextObjects`, `RuleExecutionLogs`, `RuleSetContextObjectLinks` |
| 5 | `WsdlDbContext` | `WsdlManagement/` | `WsdlRecords`, `WsdlVersions`, `WsdlTemplates`, `WsdlSyncHistory` |
| 6 | `SoapDbContext` | `SoapManagement/` | `SoapApps`, `SoapApis`, `SoapRequestFiles`, `SoapExecutionGroups`, `SoapExecutionFiles`, `SoapExecutionLogs`, `SoapParsedFields`, `SoapExtractionResults`, `SoapTestCases`, `SoapExtractors` |
| 7 | `TestDbContext` | `TestManagement/` | `ServiceApplications`, `ServiceOperations`, `ServiceRequestFiles`, `ServiceResponseFiles`, `ServiceTestSuites`, `ServiceTestCases`, `ServiceDefinitionSyncs`, `SoapNamespaces`, `ServiceAppAuthentications`, `ServiceOperationSchemas`, `ServiceRequestFileEmbeddings`, `ServiceResponseFileEmbeddings`, `ServiceTestCaseRuleSetLinks`, `ServiceTestSuiteTestCaseLinks`, `ServiceTestSuiteExecutionAudits`, `ServiceTestSuiteExecutionAuditTestCaseLinks`, `DirectExecutionAudits`, `DirectExecutionAuditResponseFileLinks` |
| 8 | `IndexingDbContext` | `IndexingManagement/` | `BinaryEmbeddingsStores`, `IndexingFileElementSearches`, `IndexingFileElementTypes`, `IndexingJsonFileElements`, `IndexingJsonFileElementMappings`, `IndexingXmlFileElements`, `IndexingXmlFileElementMappings`, `ServiceRequestIndexingStatuses`, `ServiceResponseIndexingStatuses` |
| 9 | `PermissionsDbContext` | `PermissionsManagement/` | `Roles`, `RolePermissions`, `UserPermissions`, `ResourcePermissions`, `ServiceAppPermissions`, `ServiceRequestFilesPermissions`, `ServiceTestCasesPermissions`, `ServiceTestSuitesPermissions`, `RuleSetsPermissions` |
| 10 | `FileManagementDbContext` | `FileVersionManagement/` | `FileVersions` |
| 11 | `RestDbContext` | `RestManagement/` | `RestRequestFiles` |

All are registered as scoped services in `ServiceHubDataConfig.cs` via `AddLinqToDBContext<T>()`:

```csharp
services.AddLinqToDBContext<SoapDbContext>((_, options) =>
    options.UseSqlServer(connectionString, SqlServerVersion.AutoDetect, SqlServerProvider.MicrosoftDataSqlClient));
```

## Repository layer

All repositories live under `Infrastructure/OrbitHub.Data/Repositories/`, organized by management domain. There are **two repository types**:

### Stored procedure repositories

Located in `Repositories/{Domain}/Repositories/`. Each repository:
- Takes the appropriate `DataConnection` via constructor injection
- Has an `ExecuteAsync(InputModel)` or similar method
- Calls `_ctx.QueryProcAsync<T>("[dbo].[usp_Xxx]", params)` for procedures returning rows
- Calls `_ctx.ExecuteProcAsync("[dbo].[usp_Xxx]", params)` for procedures mutating data
- Wraps results in `RepositoryResult<T>`

### View repositories

Located in `Repositories/{Domain}/Views/`. Each view repository:
- Has a `GetAllAsync()` method
- Calls `_ctx.QueryAsync<T>("SELECT * FROM [dbo].[v_Xxx]")`
- Returns a `RepositoryResult<List<T>>`

### Registration

`RepositoryRegistration.cs` registers all repositories as `AddScoped` — **112 total registrations** (72 stored procedure repos + 40 view repos). This is called automatically from `ServiceHubDataConfig.AddServiceHubData()`.

## Database schema (SSDT project)

`OrbitToolDatabase/OrbitTool.sqlproj` defines the complete database:

| Artifact | Count |
|----------|-------|
| Tables | 55 |
| Views | 40 |
| Stored Procedures | 60+ |
| Functions | 1 |
| Seed scripts | 6 |

The schema covers all domains: core settings, user management, UI pages/actions, SOAP & REST service metadata, request/response files, embeddings, indexing, test suites, rule execution, and permissions (RBAC).

### Key schema conventions

- Tables use `BIGINT` identity primary keys and `UNIQUEIDENTIFIER` public IDs where applicable.
- Views follow a `v_` prefix pattern and join related tables with friendly column names.
- Stored procedures follow a `usp_` prefix pattern with Input/Output model separation.
- A `RecordVersion` column (`ROWVERSION`) is used on key tables for optimistic concurrency.

## Dependency injection wiring

Registration flows from the web host entry point:

```
WebApp/OrbitHub.Web/Program.cs
  └─ ServiceHubDataConfig.GetConnectionString(configuration)
  └─ builder.Services.AddServiceHubData(connectionString)
       ├─ Registers all 11 DataConnection types (scoped)
       └─ Registers all repositories via RepositoryRegistration.cs (scoped)
```

Feature projects do **not** register their own DbContexts — all data infrastructure is centralized through `ServiceHubDataConfig`.

## Data integrity expectations

- Deletes should cascade through dependent records where the database schema defines cascading foreign keys.
- Execution history and audit trails are retained per the stored procedure logic.
- The `OrbitToolDatabase/scripts/OrbitTool_ResetAndRecreate.sql` script can fully drop and recreate the database schema (for development reset scenarios).

## Future considerations

- Migration scripts (`Setup/dbDesign/mssql_script_v001.sql` through `mssql_script_v009/`) provide versioned schema evolution and should be preferred for schema changes in shared environments.
- The reset script is intended for local development only.
