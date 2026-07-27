# Service Hub Enterprise — Grid JavaScript Modules

Modular, reusable JavaScript classes for datagrid UI interactions across all feature pages.

## Architecture

| File | Class | Responsibility |
|------|-------|---------------|
| `grid.js` | `ServiceHubGrid` | Orchestrator — initializes all subsystems for a datagrid |
| `pagination.js` | `ServiceHubPagination` | Page navigation, page info, page number buttons |
| `filters.js` | `ServiceHubFilters` | Search box, status dropdown, filter modal, advanced filters |
| `actions.js` | `ServiceHubRowActions` | Three-dot action menus, row selection, expand/collapse |
| `contextmenu.js` | `ServiceHubContextMenu` | Right-click context menu on data rows |

## Dependencies
- Bootstrap Icons (`bi-*`) for icons
- No jQuery or external library required

## Usage

### Quick start (all features)
```html
<script>
    document.addEventListener('DOMContentLoaded', function () {
        const grid = new ServiceHubGrid('#myGrid', {
            pageSize: 5,
            totalRecords: 25,
            onFilter: function (state) {
                console.log('Filters:', state);
                // Reload data from server or filter client-side
            },
            onPageChange: function (page, size) {
                console.log('Page:', page, 'Size:', size);
            },
            onSelect: function (ids) {
                console.log('Selected:', ids);
            }
        });
    });
</script>
```

### Standalone usage (individual modules)
```javascript
// Pagination only
const pager = new ServiceHubPagination('.pagination-footer', {
    pageSize: 10,
    totalRecords: 100,
    onPageChange: (page, size) => { /* ... */ }
});

// Filters only
const filters = new ServiceHubFilters('#myGrid', {
    onFilter: (state) => { /* ... */ }
});

// Actions only
const actions = new ServiceHubRowActions('#myGrid', {
    onSelect: (ids) => { /* ... */ }
});

// Context menu only (rows must have .has-context-menu class)
const ctx = new ServiceHubContextMenu('#myGrid', {
    items: [
        { label: 'View', icon: 'bi-eye', action: 'view' },
        { label: 'Edit', icon: 'bi-pencil', action: 'edit' },
        { type: 'divider' },
        { label: 'Delete', icon: 'bi-trash', action: 'delete', danger: true }
    ],
    onItemClick: (action, rowId) => {
        console.log(`Action: ${action}, Row: ${rowId}`);
    }
});

// Dynamic context menu items (per row)
const ctxDynamic = new ServiceHubContextMenu('#myGrid', {
    getItem: (rowId, rowEl) => {
        // Return items based on row data
        return [
            { label: 'View', icon: 'bi-eye', action: 'view' },
            { type: 'divider' },
            { label: rowEl.dataset.status === 'active' ? 'Deactivate' : 'Activate', icon: 'bi-toggle-on', action: 'toggle' }
        ];
    },
    onItemClick: (action, rowId) => {
        console.log(`Dynamic action: ${action}, Row: ${rowId}`);
    }
});
```

### Context Menu with Blazor integration
When using the Blazor `ServiceHubGrid` component with `EnableContextMenu="true"`, the context menu is automatically initialized. Subscribe to context menu events via:

**JavaScript** — listen for the `contextmenu:itemclick` custom event:
```javascript
document.querySelector('#myGrid').addEventListener('contextmenu:itemclick', (e) => {
    const { rowId, action } = e.detail;
    // Handle the action
});
```

**Blazor** — use the `ContextMenuItemsProvider` and `ContextMenuItemClicked` callbacks:
```razor
<ServiceHubGrid TItem="MyModel"
                EnableContextMenu="true"
                ContextMenuItemsProvider="@GetMenuItems"
                ContextMenuItemClicked="@OnContextMenuItemClicked" />
```

## DOM Convention

All modules expect the standard datagrid HTML structure:

```
.datagrid-card              → Grid container (pass this as the element)
├── .grid-toolbar           → Header toolbar
│   ├── .toolbar-left
│   │   ├── .search-box input
│   │   └── .meta-group
│   │       ├── .meta-pill  (records count, selected count)
│   │       ├── .status-select
│   │       └── .filter-btn
│   └── .toolbar-right      → Action buttons
│       └── .header-actions-wrap
│           ├── .action-trigger (three-dots)
│           └── .inline-actions
├── .table-wrap
│   └── table.datagrid
│       ├── thead
│       │   └── th.check-cell input[type="checkbox"]  → Select-all
│       └── tbody
│           └── tr[data-row-id="..."]
│               ├── td.check-cell input[type="checkbox"]
│               ├── .expand-btn
│               ├── .row-actions-wrap
│               │   ├── .action-trigger (three-dots)
│               │   └── .inline-actions
│               └── ...
│               └── tr.has-context-menu[data-row-id="..."]  → Context menu target rows
├── .pagination-footer
│   ├── .pagination-info
│   ├── .pagination-controls
│   │   ├── button[data-page="prev"]
│   │   ├── button.pagination-num[data-page="N"]
│   │   └── button[data-page="next"]
│   └── .footer-actions-wrap
│       ├── .action-trigger (three-dots)
│       └── .inline-actions
└── .grid-footer (standalone footer, no pagination)
    └── .footer-actions-wrap
        ├── .action-trigger (three-dots)
        └── .inline-actions
```

## Features Mapped to Files

Based on analysis of all feature pages (REST Apps, SOAP Apps, File Management, Test Suite, Monitoring Health):

| Feature | Pages Using It | JS Module |
|---------|---------------|-----------|
| Search box with icon | All grid pages | `filters.js` |
| Status dropdown filter | Applications, ExecuteHistory, HealthDashboard | `filters.js` |
| Filter modal (advanced) | SOAP Applications | `filters.js` |
| Column sorting UI | Most grid pages | Handled via Blazor `@code` |
| Row checkbox selection | Applications, Templates, RequestFiles, FileBrowser, FileLibrary, TestSuites | `actions.js` |
| Select-all checkbox | Same as above | `actions.js` |
| Three-dots action menu | SOAP Applications | `actions.js` |
| Expand/collapse rows | SOAP Applications | `actions.js` |
| Pagination footer | SOAP Applications | `pagination.js` |
| Meta pills (record count) | All grid pages | `grid.js` (orchestrator) |
