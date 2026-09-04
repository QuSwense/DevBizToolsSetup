# Spec-to-Workspace Gap Audit

## Method
- **Specs reviewed**: All files under `specs/` (README, technical docs, feature specs 01–08)
- **Workspace scanned**: Root structure, `Features/`, `Components/`, `WebApp/OrbitHub.Web/`, `Infrastructure/`, `OrbitToolDatabase/`, `mock_db/`, `service-hub/`, `service-hub-enterprise/`
- **Date**: 2026-09-03
- **Previous audit**: `specs/technical/` already audited & updated on 2026-09-02 (mock_db refs replaced with MS SQL/linq2db)

---

## Audit Summary

### Mismatches / Gaps

| # | Area | Spec Says | Workspace Has | Severity |
|---|------|-----------|---------------|----------|
| 1 | **02-soap-api-test**: Missing Feature project | `02-soap-api-test` spec covers Applications, Request Files, WSDL Sync, Templates, Execute History | No `Features/ServiceHubEnterprise.SoapApplications` or equivalent Feature project exists | 🔴 High |
| 2 | **06-monitoring-health**: Missing Feature project | `06-monitoring-health` spec with `06-01-health-dashboard` subtopic | No `Features/ServiceHubEnterprise.Monitoring*` — but there is a `HealthDashboard` component in `service-hub/service-hub.js` | 🔴 High |
| 3 | **07-ad-viewer**: Missing Feature project | `07-ad-viewer.md` spec | No Feature project for AD Viewer | 🔴 High |
| 4 | **08-settings**: Missing Feature project | `08-settings.md` spec | No Feature project for Settings | 🔴 High |
| 5 | **mock_db/ still present** | Technical specs updated to reference MS SQL/linq2db architecture | `mock_db/` directory still exists at root with Dashboard, Soap, Rest, Wsdl JSON files — possibly still referenced by some code | 🟡 Medium |
| 6 | **service-hub-enterprise/ legacy copy** | Project structure documents single .NET solution | Duplicate project tree at `service-hub-enterprise/` with its own Features/, Components/, WebApp/ — appears to be pre-restructure location | 🟡 Medium |
| 7 | **Duplicate namespace: ServiceHubEnterprise vs OrbitHub** | No mention of legacy namespaces | Both `ServiceHubEnterprise.*` and `OrbitHub.*` namespaces coexist in Features, Components, and Infrastructure | 🟡 Medium |
| 8 | **ServiceHubEnterprise.Data vs OrbitHub.Data** | `02-data-architecture.md` documents OrbitHub.Data | Both `Infrastructure/OrbitHub.Data/` and `Infrastructure/ServiceHubEnterprise.Data/` exist — unclear which is active | 🟡 Medium |
| 9 | **No Setup/ directory** | Technical spec mentions `Setup/dbDesign/` and `Setup/dockerscripts/` (Dockerized MS SQL) | No `Setup/` directory at project root | 🟡 Medium |
| 10 | **03-rest-api-test**: No subtopic for registrations vs operations | `03-01-applications.md` covers registration UI | `Features/ServiceHubEnterprise.RestApplications` exists but operations vs applications split may not match spec detail | 🟢 Low |
| 11 | **01-home-dashboard**: Subtopic count | 3 subtopic files (overview, health-metrics, executive-cards) | `Features/ServiceHubEnterprise.Dashboard` exists, subtopic coverage unclear | 🟢 Low |
| 12 | **04-file-management**: Feature project name | `04-file-management` spec covers file browser, editor, viewer, library, comparer | `Features/ServiceHubEnterprise.FileManagement` exists | ✅ Aligned |
| 13 | **05-test-suite**: Feature project name | `05-test-suite` spec covers test cases, suites, executions, success criteria | `Features/ServiceHubEnterprise.TestSuite` exists | ✅ Aligned |

### Fully Aligned
| # | Item | Status |
|---|------|--------|
| 1 | `specs/technical/` — All 4 files updated to reflect MS SQL/linq2db reality (audited 2026-09-02) | ✅ |
| 2 | `specs/04-file-management/` — Feature project `ServiceHubEnterprise.FileManagement` exists | ✅ |
| 3 | `specs/05-test-suite/` — Feature project `ServiceHubEnterprise.TestSuite` exists | ✅ |
| 4 | `specs/03-rest-api-test/` — Feature project `ServiceHubEnterprise.RestApplications` exists | ✅ |
| 5 | `OrbitToolDatabase/` — SSDT project with 55+ tables, 40+ views, 60+ stored procedures | ✅ |
| 6 | `Infrastructure/OrbitHub.Data/` — Multiple DataConnection classes, repository layer documented | ✅ |

### Unspecified but Implemented
| # | Item | Note |
|---|------|------|
| 1 | `service-hub/` — Static HTML/JS prototype with React-style components (Sidebar, Dashboard, ApplicationsTable, HealthDashboard, etc.) | No spec covers this standalone front-end |
| 2 | `service-hub-enterprise/` — Full legacy .NET project tree with its own Features, Components, WebApp | No spec mentions this alternate project root |
| 3 | `schema.sql` — Standalone SQL schema dump at root | Not referenced in any spec |
| 4 | `Components/OrbitHub.Grid/` and `Components/OrbitHub.Ui/` — Shared Blazor components (MonacoEditor, MiniDonut) | Not documented in specs |
| 5 | `OrbitToolDatabase/Seeds/` — RBAC permission seeds (ResourcePermissionsSeed, RolesSeed, UIPagesSeed) | Not mentioned in specs |

---

## Clarifications Received (2026-09-03)

| # | Question | Decision |
|---|----------|----------|
| 1 | Missing Feature projects for SOAP, Monitoring, AD Viewer, Settings | **Do not scaffold duplicates.** Update specs to reflect planned target architecture within existing `Features/` directories. SOAP & REST testing: document Test Cases, Rules, Rule Application, Test Suite Hierarchy. Test Suites aggregate test cases across SOAP and REST. |
| 2 | `mock_db/` still present | **Fully deprecated.** Remove all references from specs. Do not document as migration artifact. Persistence is strictly MS SQL. |
| 3 | `service-hub-enterprise/` duplicate tree | **Obsolete pre-restructure copy.** Ignore in all documentation. Marked for deletion. Active solution root is current repo root. |
| 4 | Namespace duality (ServiceHubEnterprise vs OrbitHub) | **Standardize on `OrbitHub.*`** exclusively across all specs, code references, models, and folder paths. |
| 5 | `Setup/` directory missing | Docker scripts and DB design docs are at root **`Setup/`** directory (`Setup/dbDesign/`, `Setup/dockerscripts/`). Update all spec paths. |

---

## Action Plan

### Spec Files to Update

| File | Changes Required |
|------|-----------------|
| `specs/README.md` | Update links, remove mock_db refs, standardize namespace |
| `specs/technical/00-technical-overview.md` | Replace ServiceHubEnterprise → OrbitHub, remove mock_db refs |
| `specs/technical/01-architecture.md` | Replace ServiceHubEnterprise → OrbitHub, update Setup/ paths |
| `specs/technical/02-data-architecture.md` | Replace ServiceHubEnterprise → OrbitHub, update Setup/ paths |
| `specs/technical/03-blazor-ui-patterns.md` | Replace ServiceHubEnterprise → OrbitHub |
| `specs/02-soap-api-test/02-soap-api-test.md` | Replace ServiceHubEnterprise → OrbitHub, add Test Cases/Rules/Rule Application docs |
| `specs/02-soap-api-test/02-01-applications.md` | Replace ServiceHubEnterprise → OrbitHub |
| `specs/03-rest-api-test/03-rest-api-test.md` | Replace ServiceHubEnterprise → OrbitHub, add Test Cases/Rules/Rule Application docs |
| `specs/03-rest-api-test/03-01-applications.md` | Replace ServiceHubEnterprise → OrbitHub |
| `specs/05-test-suite/05-test-suite.md` | Add Test Suite Hierarchy (aggregates SOAP + REST test cases) |
| `specs/05-test-suite/05-01-test-cases.md` | Add Rules and Rule Application sections |
| `specs/05-test-suite/05-02-test-suites.md` | Document multi-application, multi-protocol orchestration |
| `specs/06-monitoring-health/06-monitoring-health.md` | Replace ServiceHubEnterprise → OrbitHub |
| `specs/07-ad-viewer/07-ad-viewer.md` | Replace ServiceHubEnterprise → OrbitHub |
| `specs/08-settings/08-settings.md` | Replace ServiceHubEnterprise → OrbitHub |
| `specs/01-home-dashboard/01-home-dashboard.md` | Replace ServiceHubEnterprise → OrbitHub |
| `specs/04-file-management/04-file-management.md` | Replace ServiceHubEnterprise → OrbitHub | 
