# Repository Architecture & Workspace Rules

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