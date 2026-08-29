# Feature Redesign Template

Generic, reusable checklist for redesigning any feature project (e.g., `SoapApplications`,
`RestApplications`, `FileManagement`, `MonitoringHealth`, `TestSuite`, …) using the design
& structure principles established in the `OrbitHub.Dashboard` redesign, and
reusing the shared `ServiceHubGrid<TItem>` component for all tables.

## How to use
1. Copy this file into the target feature (e.g., `Features/<Feature>/docs/redesign-plan.md`).
2. Work through the phases top-to-bottom, ticking boxes as you go.
3. Keep the **Decision Log** filled in so the rationale survives.
4. Replace every `<Feature>` / `<domain>` placeholder for the target feature.

---

## Phase 0 — Research & Inventory (no code yet)

- [ ] **Map current architecture** of the feature:
  - Pages & routes (`*.razor` with `@page`)
  - Services / stores / repositories and how they're registered in DI (`DependencyInjection.cs`)
  - Existing models / DTOs / entities and where they live
  - Mock data files read (`mock_db/*.json`) and their exact shapes — fields, date formats, status values
  - **Hardcoded data** inline in `.razor` pages (prime candidates to move into the data + pipeline)
  - Whether the feature already references `Components/OrbitHub.Grid` (see Phase 2)
- [ ] **Data availability map**: for every metric/visual you plan, mark `✅ available / ⚠️ partial / ❌ missing`
- [ ] **Define target layout**: ordered list of full-row section cards, each specifying:
  - Title + icon
  - KPI tiles (label / value / sub)
  - Visual (donut, bars, timeline strip)
  - Drill-down table (**use `ServiceHubGrid<TItem>`**)
  - Filter type — date-range dialog, dropdown selection, or none
- [ ] **Decide architecture** (record in Decision Log):
  - Data source: self-contained `mock_db` reads (preferred) vs. reuse another feature's stores
  - Filtering: client-side on data loaded once (preferred — instant dialogs, no re-fetch)
  - Charts: custom SVG/CSS (preferred, zero new dependencies) vs. a JS charting library
  - Tables: **always `ServiceHubGrid<TItem>`** (shared component) — never hand-rolled tables
- [ ] **Get user sign-off** on the layout, data additions, and decisions before writing code

## Phase 1 — Data Layer

- [ ] Add / extend `mock_db/*.json` for each new data shape
  - Use realistic seed data
  - For date-filtered / time-series data, generate timestamps **relative to today** so the
    default "last 7 days" filter always shows data
- [ ] Add `Core/Entities/<X>Entity.cs` per new shape (plain POCO, `string` defaults)
- [ ] Add `Application/DTOs/<X>Dto.cs` mirroring the entities
- [ ] Add repository methods: interface + implementation
  - Each one is `LoadJsonAsync<T[]>("file.json") ?? Array.Empty<T>()`
- [ ] Add service methods: interface + implementation (map entity → DTO)
- [ ] Extend the page `*ViewModel` with the new collections
- [ ] Add shared UI model types if not already present (e.g., `DateRange` with `Includes(DateTime)` + `Label`)

## Phase 2 — Shared UI Kit (build once, reuse everywhere)

**Reusable, dependency-free widgets** (established in the Dashboard feature):

| Component | Purpose |
|---|---|
| `SectionCard` | Full-row card shell: title / icon / subtitle, filter pill + 📅 dialog, `HeaderActions` / `ChildContent` / `Footer` slots |
| `DateRangeFilter` | Dialog: presets (7 / 14 / 30 / 90 / All) + custom start/end + Apply / Clear |
| `KpiTile` | label / value / sub / color / icon stat tile |
| `MiniDonut` | SVG donut showing a value as % of a total |
| `TimelineStrip` | horizontal ok / degraded / down segmented status bar |

**Shared table component** (already in the solution — `OrbitHub.Grid`):

| Component | Purpose |
|---|---|
| `ServiceHubGrid<TItem>` | Generic data grid: pagination, search, sorting, selection, expand, context menu, toolbar/footer slots, column templates |

- [ ] Add a `ProjectReference` to `Components/OrbitHub.Grid/OrbitHub.Grid.csproj`
      (the Dashboard feature never referenced the Grid — if you retrofit it, add the reference there too)
- [ ] Confirm grid CSS is loaded (`grid-variables.css` + `grid.css` via `_Host.cshtml`) — the Grid's `wwwroot` is served
- [ ] **Promote** the 5 Dashboard widgets into a shared components project (e.g., extend
      `OrbitHub.Grid` or add `OrbitHub.Ui`) so every feature references one copy (recommended)
- [ ] **OR** copy them per feature and keep them in sync manually
- [ ] Add any feature-specific generic widgets if needed

### Using `ServiceHubGrid<TItem>` (reference)

See `Features/OrbitHub.SoapApplications/Pages/Applications.razor` for a full example
(`ServiceHubGrid<TItem>` + `_columns` + two-way bound state + `ToolbarCenter/ToolbarRight`).

**Markup** — pass the filtered/sorted list and let the grid paginate:

```razor
<ServiceHubGrid TItem="RestAppRow"
                Id="restAppsGrid"
                Items="@Rows"
                TotalItems="@Rows.Count"
                PageSize="5"
                EnablePagination="true"
                EnableSearch="true"
                RowIdSelector="@(r => r.Name)"
                @bind-SortColumn="_sortColumn"
                @bind-SortAscending="_sortAscending"
                @bind-SearchText="_searchText"
                Columns="@_appColumns">
</ServiceHubGrid>
```

**Columns** (define in `@code` or the code-behind):

```csharp
using OrbitHub.Grid.Components;

private IReadOnlyList<GridColumn<RestAppRow>> _appColumns = new[]
{
    new GridColumn<RestAppRow> { Title = "Application", Field = r => r.Name, Sortable = true },
    new GridColumn<RestAppRow>
    {
        Title = "Status",
        Field = r => r.Enabled ? "Enabled" : "Disabled",
        Template = ctx => builder =>
        {
            builder.OpenElement(0, "span");
            builder.AddAttribute(1, "class",
                ctx.Enabled ? "sb-badge sb-enabled" : "sb-badge sb-disabled");
            builder.AddContent(2, ctx.Enabled ? "Enabled" : "Disabled");
            builder.CloseElement();
        }
    },
    new GridColumn<RestAppRow> { Title = "Request Files", Field = r => $"{r.FilesActive} / {r.FilesTotal}", Width = "130px" },
    new GridColumn<RestAppRow> { Title = "Executions", Field = r => r.Executions.ToString(), Width = "100px" },
    new GridColumn<RestAppRow> { Title = "Success", Field = r => $"{r.SuccessPct}%", Sortable = true, Width = "100px" }
};
```

Notes:
- `GridColumn<TItem>` props: `Title`, `Field` (expression), `Width`, `Sortable`, `Template` (`RenderFragment<TItem>`), `CssClass`.
- Use `Template = ctx => builder => { … }` for badges / links / custom cells (status pills via `.sb-*`).
- The Grid is **controlled**: keep search/sort state in the parent (`_searchText`, `_sortColumn`,
  `_sortAscending`, `_currentPage`) via `@bind-*`, and pass the recomputed filtered/sorted list to `Items`.
- Optional slots: `ToolbarCenter`, `ToolbarRight`, `HeaderActions`, `FooterActions`, `RowActions` (`TItem`), `DetailRow` (`TItem`), `FilterModalBody`.

## Phase 3 — Section Cards

For each planned card (repeat this block):

- [ ] Create `UI/Components/<Card>Overview.razor` + `.razor.cs`
- [ ] Card owns its `DateRange` state (default `DateRange.LastDays(7)`) + `ApplyRange` handler
- [ ] Wrap in `SectionCard`; KPI row via `KpiTile`
- [ ] Add visual via `MiniDonut` / `TimelineStrip` / CSS bars
- [ ] Add **drill-down table via `ServiceHubGrid<TItem>`** with a `GridColumn<TItem>` list
      (badges rendered through `Template`)
- [ ] Client-side filter with `DateRange.Includes(parsed timestamp)`
- [ ] If the card uses `<HeaderActions>` or `<Footer>` → wrap the body in `<ChildContent>` (see Gotchas)

## Phase 4 — Page Wiring & Styling

- [ ] Update the feature page(s): replace old widgets with the new `SectionCard` stack
- [ ] Update code-behind `OnInitializedAsync`: load **all** datasets via `Task.WhenAll`;
      assign to the ViewModel; build per-card input mappings + `GridColumn<TItem>` lists
- [ ] Remove obsolete mapping helpers / hand-rolled tables / unused components (optional cleanup — flag with user first)
- [ ] Add CSS to the feature `wwwroot/css/*.css`:
  - `.dashboard-stack` / `.dashboard-row`, section header, `.kpi-*`, `.sb-badge*`, `.timeline-*`, `.daterange-*`, `.health-*`
  - Follow the shared `--sh-*` design tokens; add local tokens (e.g., `--sh-danger`) in `:root` only if needed
  - Avoid class names that collide with Bootstrap (`.badge` → `.sb-badge`)

## Phase 5 — Verification

- [ ] `get_errors` on all edited files
- [ ] `dotnet build` the WebApp (compiles all feature projects)
- [ ] Run the app; fetch the feature page; confirm each card renders real data,
      no JSON parse exceptions, no server-log errors
- [ ] Manual click-through: date-range presets / apply / clear, dropdowns, filters,
      grid pagination / search / sort / expand / selection
- [ ] Update repo memory (`/memories/repo/`) with new patterns & gotchas

---

## Decision Log

| # | Decision | Choice | Rationale |
|---|---|---|---|
| 1 | Data source (self-contained vs. shared store) | | |
| 2 | Filtering (client-side vs. server-side) | | |
| 3 | Charts (SVG/CSS vs. library) | | |
| 4 | Tables (shared `ServiceHubGrid` + project reference) | | |
| 5 | Shared UI kit location (shared project vs. copy) | | |
| 6 | Scope of redesign (replace all widgets? keep footer?) | | |
| 7 | ... | | |

---

## Known Gotchas (learned 2026-07-31, Dashboard redesign)

- **Razor**: you cannot mix a named RenderFragment child element (e.g., `<HeaderActions>`)
  with implicit child content — once you use a named fragment, wrap all other body content
  in `<ChildContent>...</ChildContent>` (error RZ9996 "Unrecognized child content").
- **Bootstrap collision**: avoid the generic `.badge` class (Bootstrap defines it). Use a
  prefixed `.sb-badge` + `.sb-enabled/.sb-disabled/.sb-ok/.sb-degraded/.sb-down/
  .sb-passed/.sb-failed/.sb-running/.sb-synced/.sb-parsing/.sb-none`.
- **Razor lambdas**: don't put double-quoted string literals inside `@onclick="() => Foo(\"x\")"`
  — use a dedicated handler method instead.
- **Mock dates**: keep time-series / activity mock data dated relative to today so the
  default "last 7 days" filter shows data.
- **Cross-feature references**: self-contained `LoadJsonAsync<T>` reads from `mock_db` are the
  norm, but referencing the shared `OrbitHub.Grid` project is expected for tables.
- **Grid is controlled**: filter/sort state lives in the parent (via `@bind-*`); pass the
  recomputed list to `Items` and the total to `TotalItems`.
- **CSS load order**: the feature's CSS loads after `service-hub.css`, so it wins class
  collisions — keep new class names unique anyway.

---

## Example — applying this to `SoapApplications`

- **Domain data**: `soap-apps.json`, `request-files.json`, `wsdl-records.json`,
  `wsdl-versions.json`, `wsdl-templates.json`, `templates-page.json`
  (already consumed by `SoapAppStore` / `WsdlSyncStore`; pages already use `ServiceHubGrid`)
- **New data likely needed**: execution history per request file (success/failure + dates),
  per-app WSDL sync / uptime history over a date range
- **Suggested cards**:
  1. Applications — totals, enabled/disabled, per-app table (`ServiceHubGrid<SoapApp>`, reuse existing)
  2. WSDL Sync — synced/pending/failed + last-sync per app + history over a range (`ServiceHubGrid<WsdlSyncRecord>`)
  3. Request Files — per-app active/inactive + executions success/failure over a range (`ServiceHubGrid<RequestFile>`)
  4. Templates — published/draft/archived + usage (`ServiceHubGrid<WsdlTemplate>`)
  5. Recent activity — user + date filters