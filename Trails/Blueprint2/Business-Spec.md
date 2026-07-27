# Business Specification - Enterprise Service Hub - Summary List

> Reference UI: Service Hub V7 Stable (Prod-Ready, No Border Radius)

## 1. Purpose & Personas
- Single internal web tool for QA, Business Analysts, Support/Ops across company
- Personas:
  - **Super Admin**: Full access, admin-only actions
  - **QA Engineer**: Create/Edit files, suites, test cases
  - **Business Analyst (BA)**: Default Execute/View, configurable Write access via toggle
  - **Support/Ops**: View health, execute, view files
  - **Viewer**: Read-only
- App usable by all users, Applications can only be created/edited/disabled/deleted by Admin
- Deployment: Isolated per environment (DEV/QA/UAT/PROD separate, no cross-env connection)

## 2. Application Registry (REST & SOAP - Separate Pages)
- **REST Application**: App Name, Base URL, Swagger Source URL, Summary/Description, Status Enabled/Disabled
- **SOAP Application**: App Name, Base URL, WSDL Source URL, Summary/Description, Status
- Inside Add Application dialog: Provision to add one or more APIs
  - REST API: Path, HTTP Verb (GET/POST/PUT/DELETE), Summary
  - SOAP API: Operation, Summary
- App Grid: Expand/Collapse rows
  - Collapsed: App Name, Base URL, Status, Last Updated By, Created Date, Actions
  - Expanded: Summary/Description, Swagger/WSDL URL, Created By, Last Updated By, APIs table
- Actions: Edit (dialog), Delete (confirm dialog), Disable App (confirmation, prevents execution but keeps files)
- Grid: Sortable columns, filterable, searchable

## 3. Request Files - App-Aware
- All request files (JSON/XML) belong to an App and API
- Files loaded only after App selected in dropdown
- Grid with expand/collapse:
  - Collapsed: File Name, App, API, Type JSON/XML, Sharing, Modified, Actions
  - Expanded: Which API to be tested (Path/Verb/Summary), Template variables, Validation status
- Checkbox per row + header checkbox
- Header menu bar: Filter, Clear, Delete, Execute, Show Columns, Add to Test Suite
- Columns sortable
- Actions per row: Edit, Execute, Create Test Case
- Buttons: Upload Request File (from local with App/API selector), Generate from Template

## 4. Templates
- Save templates with placeholders `{{customerId}}`
- Templates Page: Template Name, App, Placeholders chips, Created By, Actions
- Generate File Flow: Select template -> Form auto-built from placeholders -> Fill values -> Creates new request file in File Library
- Optional separate page for template editing

## 5. Reference Sync - Swagger Updater & WSDL Updater
- **Purpose**: Fetch latest spec from configured URL and save to DB for reference, validation, generation (Read-Only, not editable)
- Fields: App, Source URL, Last Synced, Version, Status
- Actions: Refresh Now (fetch from URL), View Spec (read-only), View History
- History of updates: Version, Date, Source, Updated By, Diff
- **Validation Provision**: Validate All Request Files Against Latest Schema button
  - Result: e.g., 12 Passed, 3 Failed
  - Clicking Failed count navigates to Request Files page with filter `Validation Failed` to show which files failed
- Similar flow for SOAP WSDL Sync

## 6. File Management

### File Library
- Central repo for all request files
- Sharing Model: Personal (Only Me), Shared Read (others view/execute), Shared Read/Write (others edit/clone)
- Table with sharing badges, owner, modified
- Upload to edit, provision to edit with wsdl/swagger reference

### File Browser (WebDAV)
- Year > Month > Date > Multiple subfolders organization (e.g., /2024/12/25/Batch_001)
- Breadcrumb navigation
- Left tree Year folders, right file grid
- Filter/Search: Year dropdown, File Type, Name search, Path search
- Pagination for years and files (list of all years using pagination)

### File Viewer (PDF) - Read Only
- View PDF with zoom, rotate
- Right panel:
  - Document Metadata: Title, Author, Created, Pages, Size, etc.
  - Form Fields: Can be huge - Design as expandable cards
    - Each field card: Name, Value (expandable), Type, Font, Options, Description
  - Accordion Expand/Collapse All
- Provision to load multiple PDFs and compare side-by-side with diff highlight

### Editor / Comparer
- Monaco-like editor for JSON/XML
- Header controls: Font size, Format/Prettify, Validate Syntax, Validate Against Swagger/WSDL dropdown
- Split pane: Editor A | Editor B with diff highlight (red/green)
- Bottom validation results panel

## 7. Test Suite - Redesigned Concept
- **NEW**: Test Case = Multiple Files + ONE Success Criteria (Same criteria reusable across cases)
- **Test Suite = Combination of Test Cases** (Renamed from Regression)
- **Test Cases Page**:
  - Table: Case Name, Files (chips count), Success Criteria summary, Created By, Last Result, Actions
  - Expand row: List of files + Criteria details
  - Create Test Case: Add multiple files from File Library + select/create one Success Criteria
  - Also create test case directly from Request Files row
- **Test Suites Page**:
  - Table: Suite Name, Test Cases (chips count), Total Files, Last Run Status, Actions
  - Expand: Shows included test cases
  - Create Suite: Select test cases
- **Success Criteria Page**:
  - Table: Criteria Name, Rules summary, Used in X cases, Actions
  - Create Criteria: Expected Status Code, Max Response Time, JSONPath/XPath checks, Contains/Not Contains

## 8. Executions & History
- Execute single file, multiple files, single test case, multiple test cases, full suite
- History saves: Request snapshot, Full response file, Status, Execution Date/Time, Duration, Executed By, Success Criteria result
- Base64 Handling: If response contains embedded PDF base64, auto-extract, save separately, show as separate tab `Extracted Files` in history detail with preview/download
- History view: Filterable, searchable, paginated
- Detail view: List of response files + View Details (Body, Headers, Extracted PDF)

## 9. Dashboard - Control Tower (Approved Layout - Do Not Change Without Asking)
- Date range filter: [Today | Yesterday | Last 2 Days | Last 7 Days | Last 30 Days | Custom] controls KPI cards
- KPI Cards: Files, Test Suites, Today Execs, Active Users - count + trend
- Health Card: Graph view with tooltip, filter [24h | 7d | 30d], dropdown [All Apps | Per App | Per API], legend Healthy/Degraded/Down
- Recent Activity Card: Table User/Action/Time, pagination, View All opens full searchable/filterable history page
- Recent Failures Card: Same pagination + View All opens all failures searchable
- Top Active Users list

## 10. Health Dashboard (Monitoring)
- Service list: Service Name, Status RAG dot (Healthy/Degraded/Down), Last Checked, Response Time, Uptime %
- Expand row to show: Success/Failure message, Detailed logs (scrollable code), Detail Response JSON, Messages
- Filters: App, API, Status, Date range
- Per App and Per API stats

## 11. AD Viewer (Active Directory Viewer)
- Browse OU tree left, detail right
- Search by sAMAccountName, displayName, email
- User Detail: displayName, mail, department, manager, memberOf groups badges, lastLogon, accountEnabled
- Group Detail: Members list, nested groups
- Membership check: Is User in Group?
- Actions: Export to CSV, Copy DN, Copy email - Read-only

## 12. Settings
- Users & Auth: User table, Add/remove, Enable/Disable, Role assignment, BA Write toggle
- App Settings: Global configs (file size limits, sync schedule, health check intervals)
- Audit Logs: All actions (who did what when) - filterable, searchable, pagination

## 13. UI Structure & Generic Rules
- Left sidebar menu with expand/collapse, submenu support, extensible for future menus (config-driven)
- No border radius anywhere - square corners (rounded-none)
- No Deployment page (isolated deployments, env badge read-only in sidebar header)
- Separate pages for REST, SOAP, AD, Health Dashboard, File Viewer, File Browser, Editor/Comparer, Test Suite, Settings
- Every grid: sortable, filterable, searchable, paginated, expand/collapse rows, checkbox header+row where needed
