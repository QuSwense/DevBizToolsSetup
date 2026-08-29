using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Web;
using Microsoft.JSInterop;

namespace OrbitHub.Grid.Components;

/// <summary>
/// A reusable, generic datagrid component styled for Service Hub Enterprise.
/// Supports sorting, selection, pagination, expand/collapse, search, filter modals,
/// custom row actions, detail rows, and right-click context menus.
/// </summary>
/// <typeparam name="TItem">The type of data item to display.</typeparam>
public partial class ServiceHubGrid<TItem> : ComponentBase
{
    // ── Parameters ──

    /// <summary>Optional HTML id attribute. Auto-generated if omitted.</summary>
    [Parameter] public string? Id { get; set; }

    /// <summary>The data source for the grid.</summary>
    [Parameter, EditorRequired] public IEnumerable<TItem> Items { get; set; } = [];

    /// <summary>Total record count. Defaults to Items.Count().</summary>
    [Parameter] public int TotalItems { get; set; }

    /// <summary>Number of rows per page. Default 10.</summary>
    [Parameter] public int PageSize { get; set; } = 10;

    /// <summary>Current page number (1-based).</summary>
    [Parameter] public int CurrentPage { get; set; } = 1;
    [Parameter] public EventCallback<int> CurrentPageChanged { get; set; }

    /// <summary>Visible page number buttons in pagination. Default 5.</summary>
    [Parameter] public int VisiblePages { get; set; } = 5;

    /// <summary>Column definitions for the grid.</summary>
    [Parameter] public IReadOnlyList<GridColumn<TItem>> Columns { get; set; } = [];

    /// <summary>Function to extract a unique row id from an item.</summary>
    [Parameter] public Func<TItem, string> RowIdSelector { get; set; } = item => item?.GetHashCode().ToString() ?? Guid.NewGuid().ToString();

    /// <summary>Placeholder text for the search input.</summary>
    [Parameter] public string SearchPlaceholder { get; set; } = "Search...";

    /// <summary>Text shown when the grid has no items.</summary>
    [Parameter] public string EmptyText { get; set; } = "No records found.";

    /// <summary>Title for the filter modal header.</summary>
    [Parameter] public string FilterModalTitle { get; set; } = "Filter";

    // ── Feature toggles ──

    [Parameter] public bool EnableSelection { get; set; }
    [Parameter] public bool EnablePagination { get; set; }
    [Parameter] public bool EnableSearch { get; set; }
    [Parameter] public bool EnableExpand { get; set; }

    /// <summary>Enables right-click context menu on data rows.</summary>
    [Parameter] public bool EnableContextMenu { get; set; }

    /// <summary>
    /// Invoked when a context menu item is clicked.
    /// Receives the action identifier string and the data item.
    /// </summary>
    [Parameter] public EventCallback<(string action, TItem item)> ContextMenuItemClicked { get; set; }

    /// <summary>
    /// Invoked when a Blazor-managed row action menu is dismissed by an outside
    /// click (see actions.js). Receives the row id so the consumer can clear its
    /// own open-state (e.g. _expandedActionRows) and keep it in sync with the DOM.
    /// </summary>
    [Parameter] public EventCallback<string> ActionRowClosed { get; set; }

    /// <summary>
    /// Optional function that returns context menu items for a given row dynamically.
    /// Each item: { action, label, icon?, danger?, disabled?, type? }
    /// Return null/empty to show no menu for that row.
    /// </summary>
    [Parameter] public Func<TItem, Task<List<ContextMenuItem>>?>? ContextMenuItemsProvider { get; set; }

    /// <summary>Show/hide the filter modal externally.</summary>
    [Parameter] public bool ShowFilterModal { get; set; }
    [Parameter] public EventCallback<bool> ShowFilterModalChanged { get; set; }

    /// <summary>Current search text (two-way bindable).</summary>
    [Parameter] public string SearchText { get; set; } = "";
    [Parameter] public EventCallback<string> SearchTextChanged { get; set; }

    // ── Sort state ──

    [Parameter] public string? SortColumn { get; set; }
    [Parameter] public EventCallback<string?> SortColumnChanged { get; set; }

    [Parameter] public bool SortAscending { get; set; } = true;
    [Parameter] public EventCallback<bool> SortAscendingChanged { get; set; }

    // ── Selection ──

    [Parameter] public HashSet<string> SelectedIds { get; set; } = [];
    [Parameter] public EventCallback<HashSet<string>> SelectedIdsChanged { get; set; }

    // ── Render fragments ──

    /// <summary>Content in the center of the toolbar (between meta pills and right actions).</summary>
    [Parameter] public RenderFragment? ToolbarCenter { get; set; }

    /// <summary>Content on the right side of the toolbar (action buttons).</summary>
    [Parameter] public RenderFragment? ToolbarRight { get; set; }

    /// <summary>
    /// Action buttons in the toolbar/header area that use the action-trigger + inline-actions pattern.
    /// Place a div with class "header-actions-wrap" containing .action-trigger and .inline-actions.
    /// </summary>
    [Parameter] public RenderFragment? HeaderActions { get; set; }

    /// <summary>
    /// Action buttons in the footer area that use the action-trigger + inline-actions pattern.
    /// Place a div with class "footer-actions-wrap" containing .action-trigger and .inline-actions.
    /// </summary>
    [Parameter] public RenderFragment? FooterActions { get; set; }

    /// <summary>Per-row action buttons in the Actions column.</summary>
    [Parameter] public RenderFragment<TItem>? RowActions { get; set; }

    /// <summary>Expandable detail row content.</summary>
    [Parameter] public RenderFragment<TItem>? DetailRow { get; set; }

    /// <summary>Body content for the advanced filter modal.</summary>
    [Parameter] public RenderFragment? FilterModalBody { get; set; }

    // ── Callbacks ──

    /// <summary>Invoked when "Apply Filters" in the filter modal is clicked.</summary>
    [Parameter] public EventCallback FilterApplied { get; set; }

    /// <summary>Invoked when search text changes.</summary>
    [Parameter] public EventCallback<string> SearchChanged { get; set; }

    /// <summary>Invoked when the page changes.</summary>
    [Parameter] public EventCallback<int> PageChanged { get; set; }

    /// <summary>Invoked when selection changes.</summary>
    [Parameter] public EventCallback<HashSet<string>> SelectionChanged { get; set; }

    /// <summary>Captures unmatched HTML attributes onto root .datagrid-card div.</summary>
    [Parameter(CaptureUnmatchedValues = true)] public Dictionary<string, object>? AdditionalAttributes { get; set; }

    // ── Internal state ──

    internal int _totalColumns;
    internal HashSet<string> _expandedIds = [];

    [Inject] private IJSRuntime JS { get; set; } = default!;
    private string? _gridId;
    private DotNetObjectReference<ServiceHubGrid<TItem>>? _dotNetRef;
    private readonly string _instanceId = Guid.NewGuid().ToString("N");

    internal string GridId => _gridId ??= string.IsNullOrEmpty(Id) ? $"shg-{Guid.NewGuid():N}"[..20] : Id;

    internal int ResolvedTotal => TotalItems > 0 ? TotalItems : (Items?.Count() ?? 0);

    internal int TotalPages => (int)Math.Ceiling((double)ResolvedTotal / Math.Max(1, PageSize));

    protected override void OnParametersSet()
    {
        _totalColumns = Columns.Count;
        if (EnableSelection) _totalColumns++;
        if (EnableExpand) _totalColumns++;
        if (RowActions is not null) _totalColumns++;

        if (TotalItems <= 0 && Items is not null)
            TotalItems = Items.Count();
    }

    internal string GetRowId(TItem item) => RowIdSelector(item);

    // ── Sort ──

    internal void HandleColumnClick(GridColumn<TItem> col)
    {
        if (!col.Sortable) return;
        var field = col.GetFieldName();
        if (field is null) return;
        ToggleSort(field);
    }

    internal void ToggleSort(string field)
    {
        if (SortColumn == field)
        {
            SortAscending = !SortAscending;
            SortAscendingChanged.InvokeAsync(SortAscending);
        }
        else
        {
            SortColumn = field;
            SortColumnChanged.InvokeAsync(SortColumn);
            SortAscending = true;
            SortAscendingChanged.InvokeAsync(true);
        }
        CurrentPage = 1;
        PageChanged.InvokeAsync(CurrentPage);
        StateHasChanged();
    }

    // ── Selection ──

    internal void ToggleSelect(string rowId)
    {
        if (SelectedIds.Contains(rowId))
            SelectedIds.Remove(rowId);
        else
            SelectedIds.Add(rowId);

        SelectedIdsChanged.InvokeAsync(SelectedIds);
        SelectionChanged.InvokeAsync(SelectedIds);
    }

    internal void ToggleSelectAll()
    {
        if (Items is null) return;

        if (SelectedIds.Count == Items.Count())
        {
            SelectedIds.Clear();
        }
        else
        {
            SelectedIds = [.. Items.Select(GetRowId)];
        }

        SelectedIdsChanged.InvokeAsync(SelectedIds);
        SelectionChanged.InvokeAsync(SelectedIds);
    }

    // ── Expand / Collapse ──

    internal void ToggleExpand(string rowId)
    {
        if (_expandedIds.Contains(rowId))
            _expandedIds.Remove(rowId);
        else
            _expandedIds.Add(rowId);
    }

    internal void ExpandAll()
    {
        if (Items is null) return;
        foreach (var item in Items)
            _expandedIds.Add(GetRowId(item));
    }

    internal void CollapseAll()
    {
        _expandedIds.Clear();
    }

    // ── Pagination ──

    internal void GoToPage(int page)
    {
        if (page < 1 || page > TotalPages) return;
        CurrentPage = page;
        PageChanged.InvokeAsync(CurrentPage);
        CurrentPageChanged.InvokeAsync(CurrentPage);
    }

    internal IEnumerable<int> GetPageRange()
    {
        var total = TotalPages;
        var half = VisiblePages / 2;
        var start = Math.Max(1, CurrentPage - half);
        var end = Math.Min(total, start + VisiblePages - 1);

        if (end - start + 1 < VisiblePages)
            start = Math.Max(1, end - VisiblePages + 1);

        return Enumerable.Range(start, end - start + 1);
    }

    // ── Search ──

    internal async Task OnSearchInput(ChangeEventArgs e)
    {
        SearchText = e.Value?.ToString() ?? "";
        await SearchTextChanged.InvokeAsync(SearchText);
        await SearchChanged.InvokeAsync(SearchText);
        CurrentPage = 1;
        await CurrentPageChanged.InvokeAsync(CurrentPage);
        StateHasChanged();
    }

    // ── Filter modal ──

    internal void OnShowFilterModal(bool show)
    {
        if (ShowFilterModal != show)
        {
            ShowFilterModal = show;
            ShowFilterModalChanged.InvokeAsync(show);
        }
    }

    internal void ResetFiltersClick()
    {
        SearchText = "";
        SearchTextChanged.InvokeAsync(SearchText);
        CurrentPage = 1;
        CurrentPageChanged.InvokeAsync(CurrentPage);
        StateHasChanged();
    }

    internal void CloseFilterModalOutside(MouseEventArgs e)
    {
        OnShowFilterModal(false);
    }

    internal void ApplyFilterClick()
    {
        OnShowFilterModal(false);
        CurrentPage = 1;
        CurrentPageChanged.InvokeAsync(CurrentPage);
        FilterApplied.InvokeAsync();
        StateHasChanged();
    }

    // ── Context Menu ──

    protected override async Task OnAfterRenderAsync(bool firstRender)
    {
        await base.OnAfterRenderAsync(firstRender);
        if (!firstRender) return;

        try
        {
            // Register this grid's DotNet reference so JS (grid.js / actions.js) can drive a
            // Blazor-managed right-click context menu and keep Blazor-managed row action menus
            // in sync with the DOM. JS looks the reference up lazily at interaction time to avoid
            // initialization timing races. Registered unconditionally so grids that don't enable
            // the context menu still get the action-menu close-sync bridge.
            _dotNetRef = DotNetObjectReference.Create(this);
            await JS.InvokeVoidAsync("ServiceHubContextMenuRegistry.set", GridId, _dotNetRef, _instanceId);

            // Ensure the JS grid (and context menu) is attached even when this grid renders
            // after site.js's DOMContentLoaded / blazor.navigated scan has already run.
            await JS.InvokeVoidAsync("ServiceHubGridInit.ensure", GridId);
        }
        catch
        {
            // JS interop may be unavailable (e.g. during prerender); the default menu still applies.
        }
    }

    /// <summary>
    /// Called from JS at right-click time to obtain the menu items for the given row.
    /// Returns an empty list when no <see cref="ContextMenuItemsProvider"/> is configured.
    /// </summary>
    [JSInvokable]
    public async Task<List<ContextMenuItem>> GetContextMenuItems(string rowId)
    {
        if (ContextMenuItemsProvider is null) return [];
        var item = FindItem(rowId);
        if (item is null) return [];
        var task = ContextMenuItemsProvider(item);
        return task is null ? [] : await task ?? [];
    }

    /// <summary>
    /// Called from JS when a context menu item is clicked on a Blazor-managed grid.
    /// Resolves the row and forwards (action, item) to the consumer's callback.
    /// </summary>
    [JSInvokable]
    public async Task HandleContextMenuAction(string rowId, string action)
    {
        var item = FindItem(rowId);
        if (item is null) return;
        await ContextMenuItemClicked.InvokeAsync((action, item));
    }

    /// <summary>
    /// Called from JS (actions.js) when a Blazor-managed row action menu is closed
    /// by an outside click, so the consumer can clear its open-row state.
    /// </summary>
    [JSInvokable]
    public Task CloseBlazorActionRow(string rowId) => ActionRowClosed.InvokeAsync(rowId);

    private TItem? FindItem(string rowId)
    {
        if (Items is null) return default;
        foreach (var item in Items)
        {
            if (GetRowId(item) == rowId) return item;
        }
        return default;
    }

    /// <summary>Expands the detail row for the given row id (used by the context menu "View Details").</summary>
    public void ExpandRow(string rowId)
    {
        _expandedIds.Add(rowId);
        StateHasChanged();
    }

    /// <summary>Expands or collapses the detail rows for the given row ids (used by bulk menu actions).</summary>
    public void SetRowsExpanded(IEnumerable<string> rowIds, bool expanded)
    {
        if (rowIds is null) return;
        foreach (var rowId in rowIds)
        {
            if (expanded) _expandedIds.Add(rowId);
            else _expandedIds.Remove(rowId);
        }
        StateHasChanged();
    }

    public void Dispose()
    {
        if (_dotNetRef is not null)
        {
            try { JS.InvokeVoidAsync("ServiceHubContextMenuRegistry.delete", GridId, _instanceId); } catch { }
            _dotNetRef.Dispose();
            _dotNetRef = null;
        }
        GC.SuppressFinalize(this);
    }

    /// <summary>
    /// Invoked from JS via DotNet.invokeMethodAsync when a context menu item is clicked.
    /// </summary>
    [JSInvokable]
    public static async Task OnContextMenuItemClicked(string rowId, string action)
    {
        // This is a static entry point. The consumer's page should handle this via JS interop
        // by listening to the contextmenu:itemclick custom event dispatched by the context menu.
        // Alternatively, feature pages can override this by providing their own JS interop.
        await Task.CompletedTask;
    }
}

/// <summary>
/// Represents a single item in a right-click context menu.
/// </summary>
public class ContextMenuItem
{
    /// <summary>Unique action identifier passed to the click callback.</summary>
    [JsonPropertyName("action")]
    public string Action { get; set; } = "";

    /// <summary>Display label text.</summary>
    [JsonPropertyName("label")]
    public string Label { get; set; } = "";

    /// <summary>Bootstrap Icons class (e.g., "bi-eye", "bi-trash").</summary>
    [JsonPropertyName("icon")]
    public string? Icon { get; set; }

    /// <summary>When true, the item is rendered with danger/delete styling.</summary>
    [JsonPropertyName("danger")]
    public bool Danger { get; set; }

    /// <summary>When true, the item is rendered as disabled.</summary>
    [JsonPropertyName("disabled")]
    public bool Disabled { get; set; }

    /// <summary>Set to "divider" or "header" for non-clickable items.</summary>
    [JsonPropertyName("type")]
    public string? Type { get; set; }
}
