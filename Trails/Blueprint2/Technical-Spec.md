# Technical Specification - Enterprise Service Hub - Summary List

> Reference UI: Service Hub V7 Stable - Prod-Ready, No Border Radius, Left Sidebar Extensible

## 1. Deployment Model
- Isolated per environment: DEV, QA, UAT, PROD are separate deployments/installations
- No cross-env connection allowed, no env switcher inside app
- Env badge read-only in sidebar header (e.g., PROD - Isolated)
- Each env has isolated DB, File Store, AD LDAP connection, WebDAV endpoint, Health check targets
- No Deployment page in UI

## 2. Architecture Overview
- Frontend: React, Tailwind CSS (rounded-none), Monaco Editor for JSON/XML, PDF.js for PDF viewer, Lucide icons
- Backend: REST API service (File CRUD, App CRUD, Execution Engine, Validation Engine, Sync Scheduler, Health Checker, AD Service, WebDAV Service)
- Database: Store metadata (Apps, APIs, Files, Templates, Swagger/WSDL versions, Test Cases, Suites, Criteria, Executions, Users, Audit Logs)
- File Storage: Local disk / network share for request/response files, extracted base64 PDFs, uploaded templates
- Scheduler: Cron for Swagger/WSDL sync, Health checks
- Search: Server-side filtering/sorting/pagination for all grids

## 3. Data Model

### App
- id, name, type REST/SOAP, baseUrl, swaggerUrl/wsdlUrl, summary/description (text), status Enabled/Disabled, createdBy, lastUpdatedBy, createdDate, lastModified

### API (inside App)
- id, appId, path (REST) / operation (SOAP), httpVerb, summary, authType

### RequestFile
- id, appId, apiId, fileName, type JSON/XML, content (text), sharing Personal/Shared Read/Shared RW, ownerId, lastModified, validationStatus Valid/Invalid, lastValidated

### Template
- id, appId, name, content with {{placeholders}}, placeholders[] parsed via regex, createdBy, createdDate

### Swagger/WSDL Reference
- id, appId, sourceUrl, content (JSON/YAML/XML), version, lastSynced, status Synced/Failed, history[] {version, date, updatedBy, diff}

### Test Case (New Concept - Multiple Files + One Criteria)
- id, name, fileIds[] (multiple), successCriteriaId (one), createdBy, lastModified, lastResult

### Success Criteria (Check Rules / Success Criteria)
- id, name, rules {expectedStatusCode, maxResponseTime, jsonPathChecks[] {path, expected}, xPathChecks[], contains[], notContains[], fileExistsCheck}
- reusable across test cases, usedInCount

### Test Suite (Combination of Test Cases)
- id, name, testCaseIds[] (multiple), createdBy, lastRunStatus, lastRunDate

### Execution & History
- Execution: id, type File/TestCase/Suite, refIds[], status Running/Pass/Fail, startTime, endTime, executedBy, responseFileIds[], logs (text), messages
- ResponseFile: id, executionId, fileName, content, status, extractedFiles[] (if base64 PDF detected)
- History: Execution snapshot + request snapshot + full response + extractedFiles list

### User & Auth
- User: id, name, email, role SuperAdmin/QA/BA/Support/Viewer, canWrite (bool for BA toggle), enabled, createdDate
- Role-Permission matrix: Create App (Admin only), Create/Edit File, Execute, View Health, Manage Users

### AuditLog
- id, userId, action Create/Edit/Delete/Execute/Disable/Validate, entityType App/File/TestCase/Suite/User, entityId, timestamp, details, ip

### Health
- Service: id, name, type Service/DB, appId (optional), apiId (optional), url/connectionString, status Healthy/Degraded/Down, lastChecked, latency, uptime%, message, logs, detailResponse

### AD
- Cached or live LDAP query, OU tree structure, user attributes

## 4. Module Technical Details

### REST Applications Grid
- API: GET /apps?type=REST with pagination, filtering, sorting
- Expand row: GET /apps/{id}/details includes summary/description + APIs list
- Edit: PUT /apps/{id} with validation, only Admin role middleware
- Delete: DELETE /apps/{id} with confirm, unlink files (set appId null) but not delete files
- Disable: PATCH /apps/{id}/status {status: Disabled}, check in execution engine to block execution
- Frontend: Table with expand state expandedAppId, modals showEditModal/showDeleteModal, no border radius

### Request Files
- API: GET /files?appId=&apiId=&validationStatus=&search=&sort=&page=
- Grid with checkbox: header checkbox selects all filtered, row checkbox
- Header menu bar: Filter (opens filter drawer), Clear (clears filters), Delete (bulk delete), Execute (bulk execute), Show Columns (column visibility), Add to Test Suite (bulk add)
- Expand row: GET /files/{id}/api-details
- Create Test Case from file: POST /test-cases {name, fileIds: [fileId], successCriteriaId}
- Upload: POST /files/upload with multipart, fields appId, apiId, file
- Generate: POST /files/generate {templateId, placeholderValues} -> creates new file

### Templates Page
- API: GET /templates, POST /templates, PUT, DELETE
- Placeholder parser: regex /\{\{([^}]+)\}\}/g extracts placeholders
- Generate File: Dynamic form built from placeholders, POST generates file in File Library

### Swagger Sync / WSDL Sync
- API: GET /references?type=swagger&appId=, POST /references/sync {appId}, GET /references/{id}/history
- Sync Job: Fetch from sourceUrl (HTTP GET), save content, increment version, store history, update lastSynced
- Validate All: POST /references/{id}/validate-all -> loops through files with appId, validates each against schema (AJV for JSON, XSD for XML), updates file.validationStatus, returns summary {passed, failed, failedFileIds[]}
- Failed click navigates to /request-files?filter=validationFailed&referenceId= -> frontend sets validationFilter state
- View Spec: Read-only viewer (Monaco read-only or JSON tree)
- Same for SOAP WSDL

### File Library - Editor Controller
- Frontend: Monaco Editor integration (or textarea mock with line numbers for MVP)
- Header controls:
  - Font Size select -> state fontSize
  - Format button -> prettier/json formatter, xml-formatter
  - Validate Syntax -> JSON.parse / DOMParser for XML, show Valid/Invalid badge
  - Validate Against -> dropdown of references (GET /references), button calls POST /files/{id}/validate-against {referenceId}
- Save: PUT /files/{id} with content

### File Browser WebDAV
- Backend: WebDAV client integration (list files by path)
- API: GET /webdav/files?year=&month=&date=&path=&search=&type=&page=
- Frontend: Year dropdown with pagination (list years with pagination controls), Breadcrumb component, Filter bar Year/Type/Search
- File grid with pagination, View action opens File Viewer, Download action

### File Viewer PDF - Detailed Metadata
- Backend: PDF parsing (pdf-lib / pdfjs) to extract form fields and metadata
- API: GET /pdf/{fileId}/metadata -> {documentMetadata: {}, fields: [{name, value, type, font, options[], description}]}
- Frontend: Split view left PDF viewer (PDF.js), right panel with two accordions:
  - Document Metadata: key-value table
  - Form Fields: Expandable cards per field, each card shows Name, Value (truncated with expand), Type, Font, Options list, Description. Handles huge data via virtual scroll or pagination
- Compare Mode: Two PDF viewers side by side, diff highlight for field values

### Editor / Comparer
- Two Monaco editors side by side
- Controls: Font, Format Left/Right, Compare toggle (runs diff algorithm), Validate
- Bottom panel: Validation results list

### Test Suite Redesign
- Test Case: POST /test-cases {name, fileIds[], successCriteriaId}
- Table: GET /test-cases with expand showing files list (GET /files?ids=) + criteria details (GET /criteria/{id})
- Test Suite: POST /test-suites {name, testCaseIds[]}
- Table: GET /test-suites with expand showing test cases
- Success Criteria: POST /success-criteria {name, rules}, GET /success-criteria
- Execution: POST /executions {type: TestCase/Suite, id}, backend runs files sequentially, applies criteria, saves response files, detects base64 PDFs via regex /(?i)base64 and size threshold, decodes and saves as separate file, links to execution
- Executions & History: GET /executions with filters, searchable, pagination, detail GET /executions/{id} shows response files list, logs, messages, extracted files

### Health Dashboard
- Health Checker service: Pings service URLs / DB connection, stores status, latency, message, logs, detailResponse
- API: GET /health?appId=&apiId=&status=&dateRange=, GET /health/{id}/logs
- Frontend: Cards per service with RAG dot, expand to show Success/Failure message, Detailed logs scrollable code block, Detail Response JSON, Messages
- Filters: App selector, API selector, Status, Date range [24h|7d|30d] with graph and tooltip (recharts or div bars)

### AD Viewer
- Backend: LDAP read-only connection per env
- API: GET /ad/ou-tree, GET /ad/users?search=&ou=, GET /ad/users/{id}, GET /ad/groups/{id}/members
- Frontend: Left OU Tree component, Right User Detail: displayName, mail, department, manager, memberOf badges, lastLogon, accountEnabled, search bar, Export CSV button

### Settings
- Users & Auth: GET /users, POST /users, PUT /users/{id}, DELETE, PATCH /users/{id}/toggle-write (BA Write toggle)
- App Settings: GET /settings, PUT /settings (global configs: file size limits, sync schedule cron, health check interval)
- Audit Logs: GET /audit-logs?user=&action=&entity=&dateRange=&search=&page=, searchable, filterable

## 5. UI/UX Technical Notes
- No border radius: Use Tailwind `rounded-none` on all components - cards, buttons, inputs, modals, badges
- Left sidebar: 280px expanded, 64px collapsed icon-only, dark #0f172a, white text, PROD badge amber square, menu with parent expand/collapse, openSubmenus state, extensible via config array
- Top bar: Breadcrumb, Search (Ctrl+K), User avatar
- Main content: bg #f1f5f9, cards white border-slate-200 square shadow-sm
- Grids: All tables with expand/collapse rows (expandedRowId state), checkbox header+row (selectedIds[]), sortable columns (sortColumn, sortDirection), pagination component
- Modals: Edit/Delete/Disable/Create Test Case/Upload/Generate - all square, no radius, with overlay
- Monaco editor mock with line numbers, placeholder highlight via regex
- PDF viewer with split view and accordion field cards
- Navigation: activePage state controls main render, ensure every activePage value renders a component - no blank pages (previous bug fixed)
- Keep Dashboard layout as previously approved - do not change without asking (KPI cards + date filter + health graph + recent activity + recent failures with pagination + View All)

## 6. Security & Non-Functional
- RBAC middleware: Admin-only for App CRUD, Disable
- File sharing enforcement: Personal files only owner can view, Shared Read/Write checks
- Audit: Every create/edit/delete/disable/execute/validate logged to AuditLog
- Validation: Server-side validation for JSON/XML syntax, schema validation against swagger/wSDL
- Performance: Server-side pagination for all grids, search debounce, year pagination for File Browser
- Base64 extraction: Threshold >1KB, detect PDF header %PDF after decode
- Extensibility: Sidebar menu config-driven to add future top-level or submenu items
