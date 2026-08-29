# SOAP UI Journey + Execute Engine + Test Cases — Design & Implementation Plan

> Versioned copy of the plan tracked with the repo (also mirrored in Copilot session memory).
> Status as of **2026-08-02**: Phases 0–5 **implemented and verified** (WebApp builds 0 warnings/errors; full test suite 191 passing, incl. 67 SOAP tests). Phase 6 is future work.

## TL;DR
Fix the SOAP user journey end-to-end: first-run empty states → Add App → Upload Request Files → WSDL Sync (version append) → Execute (simulated engine behind an interface) → rebuilt Execute & History page (group master-detail with Request/Response/Parsed/Extractions/Logs tabs) → Test Cases attached to request files (XPath/JSONPath/PDF extractors, run at execution). Fix key flow/validation gaps found in audit. Defer: Templates page, structural refactors (persist app store), real HTTP transport, real PDF parser, test-data seeding, Test Suite feature integration.

## Implementation status (2026-08-02) — COMPLETE through Phase 5
- **Phase 0 DONE**: models (SoapExecutionGroup/File/Log/ParsedField/Extractor/ExtractionResult/TestCase, ExecutionStage enum), SoapRequestFile extended (Content, TestCaseIds), SoapExecutionStore + SoapTestCaseStore, IExecutionEngine + SimulatedSoapExecutionEngine (deterministic; disabled-app guard; simulated failure if filename/operation contains "fail"/"error"; base64 embedded field parsing), DI registered, mock files created, config ExecutionStageDelayMs.
- **Phase 1 DONE**: first-run empty states on Applications / Request Files / WSDL Sync (0-apps CTA), Execute & History empty state.
- **Phase 2 DONE**: Execute in row actions + Actions dropdown (Execute Selected); unique group id; progress modal with per-file stage stepper; persists via SoapExecutionStore; navigates to /soap/execute-history?group=.
- **Phase 3 DONE**: ExecuteHistory page rebuilt (filter bar file/app/status/date + ?file= &app= &group= query entry points; ServiceHubGrid&lt;SoapExecutionGroup&gt;; master-detail; ExecutionFileDetails component with Request/Response/Parsed/Extractions/Logs tabs). Monaco NOT reused (plain `<pre>` viewer) — noted as later polish.
- **Phase 4 DONE**: "Test Cases" row action → list modal → create/edit modal with extractors (source/type xpath|jsonpath|pdf/path/expected); persists to soap-test-cases.json; engine runs enabled test cases at RunningTestCases stage; results in Extractions tab.
- **Phase 5 DONE**: WSDL Sync version-append flow (reuse most recent record, bump VersionNumber + VersionCount) + Users:CurrentUser; Copy/Rollback/Download implemented; cascade-delete on app delete (request files + test cases + WSDL records, keeps execution history); duplicate-file validation on upload/edit; operation-must-belong validation on edit; WsdlSyncStore null-safe lists.
- **DEFERRED (per plan)**: auth-field required validation (kept optional — existing test AddApplicationPersistsToStore expects Basic-without-username to succeed), persist SoapAppStore CRUD, Monaco for request/response viewers, real transport, real PDF parser, test-data folder, Test Suite integration, Templates page.
- **Tests**: 67 SOAP tests pass (engine, both stores, ExecuteHistory page, RequestFiles page incl. execute + duplicate-upload, existing suites). Full suite 191 pass. WebApp builds 0 warnings/errors.

## Confirmed decisions (from user Q&A)
1. Execution engine: SIMULATED behind `IExecutionEngine` interface; real transport pluggable later.
2. Execution storage: NEW `mock_db/Soap/soap-executions.json` with group-based schema; shared `Soap/Request/request-executions.json` (Dashboard/REST/overview cards) untouched.
3. File content: add optional `Content` field to request files; uploads capture it; seeded files get synthesized envelopes at execute time.
4. First-run data: KEEP soap-apps.json seeds + robust empty states (no data wipe).
5. History page: single page master-detail + per-file history. Request Files row action "History" → navigate to `/soap/execute-history?file=<name>&app=<app>`; same reachable via filters on the page.
6. Audit scope: include key flow/validation fixes now (WSDL version append, duplicate-file validation, disabled-app execute guard, cascade-delete awareness); defer structural refactors.
7. Custom tags → REDESIGNED: NOT at execution time. Test case(s) attached to a request file from the Request Files page ("Create Test Case"). Test case defines extractors: XPath (XML) / JSONPath (JSON) / PDF fields&values, source = request|response, optional expected value. Runs at execution; results shown in detail "Test/Extractions" tab. (Supersedes the earlier "custom tag" idea.)

## Current state (facts from discovery)
- Pages/routes: `/soap/overview` (SoapOverview, 5 SectionCards), `/soap/applications`, `/soap/request-files`, `/soap/templates` (defer), `/soap/wsdl-sync`, `/soap/execute-history` (rebuilt).
- Services (singleton, DI in `DependencyInjection/ServiceCollectionExtensions.cs`): `MockDbLoader`, `SoapAppStore`, `WsdlSyncStore`, `RequestExecutionStore`, `SoapExecutionStore`, `SoapTestCaseStore`, `IExecutionEngine`.
- `SoapRequestFile` is the shared model for the Request Files page (no local record). Grids keyed on FileName.
- Upload modal uses dropdowns for app/operation (ops from SoapAppStore). Duplicate-filename guard added.
- WSDL Sync: version-append flow, `Users:CurrentUser`, Copy/Rollback/Download implemented; Monaco editors for WSDL content/comparison.
- Test infra: bUnit `BunitTestBase`, `MockDbFixture.CreateTempMockDb`/`TempMockDb`, naming `{Method}_{Scenario}_{Expected}`.
- Grid: `ServiceHubGrid<TItem>` slots: ToolbarCenter/ToolbarRight/HeaderActions/FooterActions/RowActions/DetailRow/FilterModalBody/EmptyText (string only).
- Config patterns: `MockDb:RequestFilesDelayMs`, `MockDb:ExecutionStageDelayMs` (tests set 0); `Users:CurrentUser` ("Priya Sharma").
- Standards: code-behind .razor.cs, CSS vars --sh-*, 120-col, XML doc comments, records for DTOs, camelCase JSON via MockDbLoader.SaveJsonAsync.

## Phases

### Phase 0 — Data layer & engine foundation
Steps:
- 0.1 New models in `Features/OrbitHub.SoapApplications/Models/`:
  - `SoapExecutionGroup`: Id, StartedAt, FinishedAt, TriggeredBy, Status, DurationMs, Files: SoapExecutionFile[].
  - `SoapExecutionFile`: FileName, AppName, Operation, Status, Stage (ExecutionStage), StagesCompleted/Total, DurationMs, RequestContent, ResponseContent, ResponseMimeType, ParsedFields: SoapParsedField[], Extractions: SoapExtractionResult[], Logs: SoapExecutionLog[].
  - `ExecutionStage` enum in `Core/Enums/`: Queued, BuildingRequest, SendingRequest, AwaitingResponse, ParsingResponse, RunningTestCases, Complete.
  - `SoapExecutionLog`: Id, Timestamp, Type (info/warning/error/request/response/assertion), Message.
  - `SoapParsedField`: Name, Source, Path, Value, IsEmbedded, DecodedPreview (for base64).
  - `SoapTestCase` + `SoapExtractor`: TestCase(Id, Name, Description, AppName, FileName, Enabled, audit fields, Extractors[]). Extractor(Id, Name, Source(request|response), Type(xpath|jsonpath|pdf), Path, ExpectedValue).
  - `SoapExtractionResult`: ExtractorId, Name, Source, Type, Path, Value, Expected, Passed.
  - Extend `SoapRequestFile` with optional `Content` + `TestCaseIds` (string[]); unify the local RequestFile record → use this model in RequestFiles page.
- 0.2 New mock_db files under `mock_db/Soap/`: `soap-executions.json` = `[]`, `soap-test-cases.json` = `[]`.
- 0.3 `Services/Execution/IExecutionEngine.cs` + `Services/Execution/SimulatedSoapExecutionEngine.cs`:
  - BuildRequestContent(file, app) (use stored Content or synthesize envelope from operation+app).
  - GenerateResponseContent (deterministic, may embed base64/PDF-like blobs for parsed-fields demo).
  - RunAsync(group, onProgress, ct): advances stages per file with configurable delay; runs enabled test cases (Phase 4 wires in); writes logs; terminal status.
- 0.4 New stores `SoapExecutionStore` (soap-executions.json read/write via MockDbLoader.SaveJsonAsync) + `SoapTestCaseStore` (soap-test-cases.json). Register singleton in `DependencyInjection/ServiceCollectionExtensions.cs` along with `IExecutionEngine`.
- 0.5 Config `MockDb:ExecutionStageDelayMs` (default ~500ms; tests set 0) following RequestFilesDelayMs pattern.

### Phase 1 — Empty-state UI journey
- 1.1 `Pages/Applications.razor(.cs)`: first-run empty state (0 apps) — hero card + "Add Application" CTA opening existing add modal; keep grid EmptyText for filtered-empty.
- 1.2 `Pages/RequestFiles.razor(.cs)`: 0-files → empty state + "Upload File" CTA; 0-apps → guidance + link to `/soap/applications`, disable upload.
- 1.3 `Pages/WsdlSync.razor(.cs)`: 0-apps empty state → CTA to Applications; keep/improve existing no-syncs state.
- 1.4 `Pages/ExecuteHistory.razor`: 0-groups empty state → CTA to Request Files.
- 1.5 `Components/*Overview`: verify zero-data renders (no crashes) — light touch only.

### Phase 2 — Execute flow on Request Files
- 2.1 Add "Execute" to Actions dropdown (bulk, uses selected rows) + RowActions (execute single file) in RequestFiles.razor.
- 2.2 Handler in RequestFiles.razor.cs: create group (unique id `exg-`), resolve content (stored or synthesized), submit to SimulatedSoapExecutionEngine and WAIT through the execution cycle while showing per-file stage progress "as per server update" (model as a server-side job; client reflects simulated job-state updates — a waiting cycle, not true real-time push), persist via SoapExecutionStore on completion, toast + NavigateTo("/soap/execute-history") (group pre-selected) or inline completion panel.
- 2.3 Progress UI: per-file stage stepper with status badges (Queued→…→Complete).
- 2.4 Guards: disabled-app execute blocked/warned; empty selection handled.

### Phase 3 — Execute & History page (rebuild)
- 3.1 Rebuild `Pages/ExecuteHistory.razor(.cs)` (drop ExecutionsOverview card):
  - Filter bar: file picker (from request files), app, date range, status; honor `?file=&app=` query (per-file history entry point).
  - History grid `ServiceHubGrid<SoapExecutionGroup>`: Id, StartedAt, TriggeredBy, App(s), File count, Status, Duration.
  - Master-detail: select group → file list → select file → detail tabs:
    - Request: content viewer (plain `<pre>` — Monaco reuse deferred).
    - Response: content viewer + mime.
    - Parsed fields: SoapParsedField table incl. base64 decode preview.
    - Test/Extractions: SoapExtractionResult table.
    - Logs: timeline of SoapExecutionLog with type badges.
  - Per-file mode (`?file=`): filter groups to those containing the file; highlight that file's per-group result.
- 3.2 Add "History" row action on Request Files → NavigateTo("/soap/execute-history?file=...&app=...").
- 3.3 Sidebar label unchanged ("Execute & History").

### Phase 4 — Test cases (attached to request files)
- 4.1 "Create Test Case" entry on Request Files (RowActions). Modal: name, description, extractor list (source, type XPath/JSONPath/PDF, path, optional expected value), enable/disable. Persist via SoapTestCaseStore.
- 4.2 Engine: after ParsingResponse run enabled test cases for the file; evaluate XPath (System.Xml.XPath, with local-name fallback for namespaces) / JSONPath (JsonNode) / PDF (simulated text search now — real parser later, needs package approval). Store SoapExtractionResult[] on the file.
- 4.3 Detail "Test/Extractions" tab renders results.
- 4.4 Validation: extractor source+path required; test-case name unique per app+file.

### Phase 5 — Audit fixes & validation (from code review)
- 5.1 WSDL Sync: version-append flow — if no record for app: create record + v1; else append version N+1 and update VersionCount. Use `Users:CurrentUser` config. Implement CopyWsdlContent (clipboard), Rollback (create new version with restored content), DownloadWsdl (via existing download.js pattern).
- 5.2 Cascade-delete awareness: deleting an app warns about dependent request files / test cases / WSDL records (counts); cascades on confirm. Execution history kept.
- 5.3 Disabled-app execute guard (enforce in engine + UI).
- 5.4 Unify SoapRequestFile model (remove local RequestFile record).
- 5.5 Operation-exists validation on edit; auth-config validation intentionally left optional (existing test expects Basic-without-username to succeed).
- 5.6 DEFERRED: persist SoapAppStore CRUD to soap-apps.json; other structural refactors.

### Phase 6 — Later phases (captured, out of scope now)
- 6.1 Modular test-data folder: request/response XML per app+operation, mock WSDL files with versions (organized e.g. mock_db/soap/...).
- 6.2 Test Suite feature (`OrbitHub.TestSuite`) integration with test cases.
- 6.3 Real HTTP transport behind IExecutionEngine; real PDF extraction lib (package decision + approval required).
- 6.4 Templates page enhancements.

## Relevant files
- `Features/OrbitHub.SoapApplications/Models/` — new + extended models (SoapRequestFile).
- `Features/OrbitHub.SoapApplications/Core/Enums/` — ExecutionStage.
- `Features/OrbitHub.SoapApplications/Services/Execution/IExecutionEngine.cs`, `SimulatedSoapExecutionEngine.cs`.
- `Features/OrbitHub.SoapApplications/Services/SoapExecutionStore.cs`, `SoapTestCaseStore.cs`.
- `Features/OrbitHub.SoapApplications/DependencyInjection/ServiceCollectionExtensions.cs` — register new services.
- `Features/OrbitHub.SoapApplications/Pages/Applications.razor(.cs)`, `RequestFiles.razor(.cs)`, `WsdlSync.razor(.cs)`, `ExecuteHistory.razor(.cs)`.
- `Features/OrbitHub.SoapApplications/Components/ExecutionFileDetails.razor(.cs)`.
- `mock_db/Soap/soap-executions.json`, `mock_db/Soap/soap-test-cases.json` (new); `mock_db/Soap/Request/request-files.json` (optional Content).
- `WebApp/OrbitHub.Web/appsettings.json` — MockDb:ExecutionStageDelayMs.
- Tests: `tests/OrbitHub.Tests/SoapApplications/`.

## Verification
- Per phase: `dotnet build WebApp/OrbitHub.Web/OrbitHub.Web.csproj`; `dotnet test tests/OrbitHub.Tests/...`.
- New bUnit tests: SimulatedSoapExecutionEngineTests (stages, group id, status), SoapExecutionStoreTests/SoapTestCaseStoreTests (round-trip JSON), RequestFilesPageTests (execute button → group created+persisted, duplicate-upload validation, History nav), ExecuteHistoryPageTests (renders groups, ?file= filter, detail tabs), empty-state tests.
- Manual journey: fresh run → empty states → Add App → Upload files → WSDL Sync creates v1 then v2 → Execute single+bulk → progress animates → history page shows group → drill into file → Request/Response/Parsed/Logs tabs → create test case (XPath) → re-execute → Test tab shows pass/fail + extracted values → per-file History navigation.
- get_errors on all edited files.

## Decisions log
- Simulated engine behind interface (no real HTTP now).
- Dedicated soap-executions.json group schema; shared request-executions.json untouched.
- Optional Content on request files; synthesized envelopes for seeds.
- Keep seeds + empty states (no wipe).
- History: single master-detail page + `?file=` per-file entry; filters on page.
- Test cases = extractors (XPath/JSONPath/PDF) attached to request files; run at execution; results in detail tab. Replaces "custom tags".
- Include key audit fixes now (WSDL version append, duplicates, disabled guard, cascade awareness); defer refactors.
- Monaco reuse for XML viewers deferred (plain `<pre>` used).

## Further considerations
1. PDF extraction: real parser needs a NuGet package (e.g., PdfPig) → requires csproj check + user approval before adding (project rule: refer to .csproj first). Start with simulated text-search extractor; real parser later.
2. This is NOT real-time progress — execution is a waiting cycle. The client submits, then waits while stages advance; progress is shown "as per server update", i.e., model execution as a server-side job and reflect its state via updates (simulated server polling / job-state feed in the mock). No true real-time push needed.
3. Execution of files from disabled apps → block + warn.
