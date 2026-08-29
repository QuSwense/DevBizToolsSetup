# 01. Architecture Specification

## Solution layout

The application is organized around a central web host and feature-specific projects. The current workspace shows the following primary groupings:

- `WebApp/ServiceHubEnterprise.Web` — host application and startup configuration
- `Features/ServiceHubEnterprise.*` — feature modules for dashboard, SOAP, REST, file management, monitoring, AD viewer, settings, and tests
- `Components/` — reusable UI and grid components
- `mock_db/` — mock seed and runtime data content for feature modules
- `tests/` — automated validation for the application

## Architectural principles

1. Feature isolation: each feature owns its pages, components, and service/store logic.
2. Shared runtime services: common infrastructure is registered centrally in the host `Program.cs`.
3. Mock-driven behavior: business logic and UI flows rely on the mock data store in `mock_db/` rather than direct database initialization for all scenarios.
4. Route-based feature access: each feature is exposed through distinct route patterns such as `/soap/overview`, `/rest/applications`, `/health`, and `/settings`.

## Dependency wiring

The web host uses feature extension methods to wire all major modules:

- `AddDashboardFeature()`
- `AddRestApplicationsFeature()`
- `AddSoapApplicationsFeature()`
- `AddFileManagementFeature()`
- `AddTestSuiteFeature()`
- `AddMonitoringHealthFeature()`
- `AddADViewerFeature()`
- `AddSettingsFeature()`

This pattern keeps feature registration explicit and reduces cross-feature coupling.

## Subsystem boundaries

- Dashboard: landing and operational summary views
- SOAP: app management, request artifacts, test execution, and WSDL workflows
- REST: API app management, request files, Swagger sync, and execution history
- File Management: browser/editor/viewer/library/comparer utilities
- Test Suite: case execution and result tracking
- Monitoring & Health: health dashboards and operational telemetry
- AD Viewer: directory view and user/entity visibility
- Settings: configuration and user-level preferences

## Architectural guidance for change work

When editing a feature, keep the change localized to the owning feature project and update the corresponding specification file. Avoid broad refactors unless the user explicitly requests a cross-cutting change.
