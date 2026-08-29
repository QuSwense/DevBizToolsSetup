
# 02-01. SOAP Applications

## Scope  
This feature manages SOAP applications without a UI. It provides cataloging, lifecycle control, and execution tools.

## Routes  
- `/soap/applications` — Central endpoint for listing, managing, and running SOAP apps.

## Core Outcomes  
- **API Governance:** Register, enable/disable, and organize SOAP APIs in one place.  
- **Execution Groups:** Select multiple request files, run them together, and compare results.  
- **Artifact Links:** Connect each app to WSDLs, request templates, and execution logs.

## View Summary  
The UI is an interactive grid showing all SOAP apps with search, filters, and actions.

### Header  
- Search bar filters by **Application Name**, **Last Updated**, **Created**, **Operation Name**.  
- Badges show selected rows and total records.  
- **Register New Application** button adds a new app.

### Catalog Grid  
Each row shows:  
- **App Name** — Display name of the application.  
- **Base URL** — Root endpoint for SOAP calls.  
- **Status** — Enabled/Disabled toggle.  
- **Last Updated** — User + timestamp of last change.  
- **Actions** — Displayed as an **ellipses button**. On click, a **dropdown menu** appears with grouped buttons:  
  - **Add Test Case** — Create and validate a request file test case.  
  - **View Request Files** — Navigate to `/soap/request-files?appId={id}`.  
  - **View WSDL Sync** — Navigate to `/soap/wsdl-sync?appId={id}`.  
  - **View Execution History** — Navigate to `/soap/execute-history?appId={id}`.  
  - **Edit / Delete / Status Toggle** — Manage the application definition.  
- Clicking outside the dropdown closes the menu automatically.

### Row Expansion  
Expanded details include:  
- **Description** — Optional text about the app.  
- **Status Badge** — Visual indicator (Green = Enabled, Gray = Disabled).  
- **Created At / Created By** — Metadata of creation.  
- **Last Updated At / Last Updated By** — Metadata of last change.  
- **Authentication Type** — Basic or NTLM.  
- **Soap Apis (Operation)** — List of operations with **Name**, **Description**, **Action**, and count badge.  
- **Base Url** — Root endpoint repeated for clarity.  
- **Version** — Format *YY.QQ.NN*.  
- **Update History** — Shows **User**, system-generated **Log**, and optional **Comment**.

### Footer  
- Badges for selected rows and total records.  
- Pagination controls with page numbers, previous/next navigation.

## Implementation Anchors  
- UI: `Applications.razor`  
- Service: `ISoapApplicationService.cs`  
- Data: `mock_db/Soap/applications.json`

## Expected Behavior  
1. **Batch Trigger:** “New Execution Group” opens a modal to select request files and run them together.  
2. **Response Drawer:** Executions open a multi-tab view showing request/response pairs with syntax highlighting (XML/JSON/PDF).  
3. **Dynamic Filtering:** Search and filters update results instantly without reload.  
4. **CRUD Safeguards:** Deletion prompts confirmation if dependencies exist.

---