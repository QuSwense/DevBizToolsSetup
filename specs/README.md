# Service Hub Enterprise Specification Index

This folder holds the current project specification set, organized by feature area and technical concern. The documents are aligned to the active codebase structure in the workspace, including the major feature projects under `Features/` and the web host in `WebApp/OrbitHub.Web`.

## 00. Technical specs

- [00-technical-overview.md](technical/00-technical-overview.md)
- [01-architecture.md](technical/01-architecture.md)
- [02-data-architecture.md](technical/02-data-architecture.md)
- [03-blazor-ui-patterns.md](technical/03-blazor-ui-patterns.md)

## 01. Home Dashboard

- [01-home-dashboard.md](01-home-dashboard/01-home-dashboard.md)
- [01-01-dashboard-overview.md](01-home-dashboard/01-01-dashboard-overview.md)
- [01-02-health-metrics.md](01-home-dashboard/01-02-health-metrics.md)
- [01-03-executive-dashboard-cards.md](01-home-dashboard/01-03-executive-dashboard-cards.md)

## 02. Soap API Test

- [02-soap-api-test.md](02-soap-api-test/02-soap-api-test.md)
- [02-01-applications.md](02-soap-api-test/02-01-applications.md)
- [02-02-request-files.md](02-soap-api-test/02-02-request-files.md)
- [02-03-wsdl-sync.md](02-soap-api-test/02-03-wsdl-sync.md)
- [02-04-templates.md](02-soap-api-test/02-04-templates.md)
- [02-05-execute-history.md](02-soap-api-test/02-05-execute-history.md)
- [02-06-test-cases.md](02-soap-api-test/02-06-test-cases.md) — dedicated test cases per application and per request file
- [02-07-rules.md](02-soap-api-test/02-07-rules.md) — execution rule management for SOAP

## 03. Rest API Test

- [03-rest-api-test.md](03-rest-api-test/03-rest-api-test.md)
- [03-01-applications.md](03-rest-api-test/03-01-applications.md)
- [03-02-request-files.md](03-rest-api-test/03-02-request-files.md)
- [03-03-swagger-sync.md](03-rest-api-test/03-03-swagger-sync.md)
- [03-04-templates.md](03-rest-api-test/03-04-templates.md)
- [03-05-execute-history.md](03-rest-api-test/03-05-execute-history.md)
- [03-06-test-cases.md](03-rest-api-test/03-06-test-cases.md) — dedicated test cases per application and per request file
- [03-07-rules.md](03-rest-api-test/03-07-rules.md) — execution rule management for REST

## 04. File Management

- [04-file-management.md](04-file-management/04-file-management.md)
- [04-01-file-browser.md](04-file-management/04-01-file-browser.md)
- [04-02-file-editor.md](04-file-management/04-02-file-editor.md)
- [04-03-file-viewer.md](04-file-management/04-03-file-viewer.md)
- [04-04-file-library.md](04-file-management/04-04-file-library.md)
- [04-05-comparer.md](04-file-management/04-05-comparer.md)

## 05. Test Suite

- [05-test-suite.md](05-test-suite/05-test-suite.md)
- [05-01-test-cases.md](05-test-suite/05-01-test-cases.md)
- [05-02-test-suites.md](05-test-suite/05-02-test-suites.md)
- [05-03-executions-history.md](05-test-suite/05-03-executions-history.md)
- [05-04-success-criteria.md](05-test-suite/05-04-success-criteria.md)
- [05-05-rules.md](05-test-suite/05-05-rules.md) — shared global rule library for automated evaluation

## 06. Monitoring & Health

- [06-monitoring-health.md](06-monitoring-health/06-monitoring-health.md)
- [06-01-health-dashboard.md](06-monitoring-health/06-01-health-dashboard.md)

## 07. AD Viewer

- [07-ad-viewer.md](07-ad-viewer/07-ad-viewer.md)

## 08. Settings

- [08-settings.md](08-settings/08-settings.md)

## Working rule

Use these documents as the source of truth for business intent, feature decomposition, and technical integration. Product behavior should be implemented from the active feature pages and their shared services, not from stale or duplicated documentation.
