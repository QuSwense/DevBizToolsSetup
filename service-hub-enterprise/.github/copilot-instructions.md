# Project Coding Standards

## Architecture & Structure
- Features are organized in: `Features/SoapApplications/` and `Features/Dashboard/`
- Each feature follows: `[FeatureName]/Pages/`, `[FeatureName]/Components/`, `[FeatureName]/Services/`

## Blazor Development
- **ALWAYS** use code-behind files (`.razor.cs`) instead of `@code` blocks
- Pattern: `Page.razor` + `Page.razor.cs` + `Page.razor.css`
- Code-behind class must be `public partial class PageName : ComponentBase`

## CSS Standards
- Define default values as CSS variables: `--variable-name: value;`
- Use variables in custom styles: `property: var(--variable-name);`
- Keep variables in: `wwwroot/css/variables.css`

## C# Coding Standards
- Use PascalCase for public properties and methods
- Use camelCase for private fields (prefixed with `_`)
- Async methods should have `Async` suffix
- Use `// <summary>` XML comments for public APIs
- Maximum line length: 120 characters

## Critical Solution Map
- Solution File: `ServiceHubEnterprise.slnx`
- Host Web Project: `WebApp/ServiceHubEnterprise.Web/ServiceHubEnterprise.Web.csproj`
- Feature Projects (under `Features/`):
  - `Features/ServiceHubEnterprise.ADViewer/ServiceHubEnterprise.ADViewer.csproj`
  - `Features/ServiceHubEnterprise.Dashboard/ServiceHubEnterprise.Dashboard.csproj`
  - `Features/ServiceHubEnterprise.FileManagement/ServiceHubEnterprise.FileManagement.csproj`
  - `Features/ServiceHubEnterprise.MonitoringHealth/ServiceHubEnterprise.MonitoringHealth.csproj`
  - `Features/ServiceHubEnterprise.RestApplications/ServiceHubEnterprise.RestApplications.csproj`
  - `Features/ServiceHubEnterprise.Settings/ServiceHubEnterprise.Settings.csproj`
  - `Features/ServiceHubEnterprise.SoapApplications/ServiceHubEnterprise.SoapApplications.csproj`
  - `Features/ServiceHubEnterprise.TestSuite/ServiceHubEnterprise.TestSuite.csproj`

## Execution & Scope Rules
- **Zero Unrequested Edits:** Modify ONLY the lines, functions, or files required to fulfill the user's explicit request. Do NOT refactor, reformat, or clean up surrounding code.
- **Dependency Awareness:** Always refer to the relevant `.csproj` file before introducing or updating NuGet packages in a project.
- **Solution Safety:** Do not alter project references in `ServiceHubEnterprise.slnx` unless explicitly instructed.
- **Out-of-Scope Changes:** If a task requires modifying files outside the requested context, stop and ask for permission before generating code.

## Business Spec — Mock Database (mock_db) Configuration

The solution uses a central `mock_db/` folder at the solution root for all mock/seed data (JSON files, WSDL content, templates).

**Configuration Rules:**
- The path to `mock_db/` is configured via `MockDb:Path` in the WebApp's `appsettings.json`.
- The path is resolved by `MockDbLoader` (in `Features/ServiceHubEnterprise.SoapApplications/Services/`) using `IConfiguration` exclusively — no fallback logic.
- If `MockDb:Path` is missing or empty, `MockDbLoader` throws `InvalidOperationException`.
- If the resolved directory does not exist, `MockDbLoader` throws `DirectoryNotFoundException`.
- `MockDbLoader` is registered as a singleton via DI in `ServiceHubEnterprise.SoapApplications/DependencyInjection.cs`.

**Usage:**
- Consumed by `SoapAppStore`, `WsdlSyncStore`, and Razor pages (`RequestFiles.razor`, `Templates.razor`, `WsdlSync.razor`).
- The path is relative to `Directory.GetCurrentDirectory()` (i.e., the WebApp's working directory). Currently set to `"../../mock_db"`.
