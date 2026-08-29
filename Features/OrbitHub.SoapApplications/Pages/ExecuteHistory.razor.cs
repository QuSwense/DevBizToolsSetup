using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.WebUtilities;
using OrbitHub.Grid.Components;
using OrbitHub.SoapApplications.Models;
using OrbitHub.SoapApplications.Services;

namespace OrbitHub.SoapApplications.Pages;

/// <summary>
/// Code-behind for the Execute &amp; History page. Shows execution groups in a
/// filterable history grid, a per-group file list and per-file detail tabs
/// (Request / Response / Parsed fields / Extractions / Logs). Supports direct
/// entry points via query params: ?group=&lt;id&gt; (from the Execute flow),
/// ?file=&lt;name&gt;&amp;app=&lt;app&gt; (per-file history from Request Files).
/// </summary>
public partial class ExecuteHistory
{
    [Inject] private SoapExecutionStore ExecutionStore { get; set; } = default!;
    [Inject] private SoapAppStore AppStore { get; set; } = default!;
    [Inject] private NavigationManager Nav { get; set; } = default!;

    private bool _isLoading = true;
    private SoapExecutionGroup[] _groups = [];
    private SoapRequestFile[] _files = [];

    // Filter state
    private string _filterFile = "";
    private string _filterApp = "";
    private string _filterStatus = "";
    private DateTime? _filterDateFrom;
    private DateTime? _filterDateTo;
    private string _searchText = "";
    private string _sortColumn = "";
    private bool _sortAscending = true;
    private int _currentPage = 1;

    // Selection (master-detail)
    private string? _selectedGroupId;
    private string? _selectedFileId;

    private List<GridColumn<SoapExecutionGroup>> _columns = [];

    protected override async Task OnInitializedAsync()
    {
        await base.OnInitializedAsync();

        _groups = [.. ExecutionStore.Groups];
        // Request files are not yet backed by a database table — previously loaded from
        // mock JSON. TODO: load from MSSQL (SoapRequestFiles) once the schema exists.
        _files = [];

        ReadQueryParams();

        _columns =
        [
            new() { Title = "Execution", Sortable = true, Field = g => g.Id, Width = "150px", CssClass = "mono-text" },
            new() { Title = "Started", Sortable = true, Field = g => g.StartedAt, Width = "170px" },
            new() { Title = "Applications", Sortable = true, Field = g => g.AppsSummary },
            new() { Title = "Files", Sortable = true, Field = g => g.FileCount, Width = "70px" },
            new()
            {
                Title = "Status",
                Sortable = true,
                Field = g => g.Status,
                Template = context => builder =>
                {
                    var (cls, label) = GetStatusBadge(context.Status);
                    builder.OpenElement(0, "span");
                    builder.AddAttribute(1, "class", $"status-badge {cls}");
                    builder.AddContent(2, label);
                    builder.CloseElement();
                }
            },
            new() { Title = "Duration", Sortable = true, Field = g => g.DurationMs, Width = "110px" },
            new() { Title = "Triggered By", Sortable = true, Field = g => g.TriggeredBy }
        ];

        _isLoading = false;
    }

    private void ReadQueryParams()
    {
        var query = QueryHelpers.ParseQuery(new Uri(Nav.Uri).Query);
        if (query.TryGetValue("file", out var fileVal) && !string.IsNullOrWhiteSpace(fileVal))
            _filterFile = fileVal.ToString();
        if (query.TryGetValue("app", out var appVal) && !string.IsNullOrWhiteSpace(appVal))
            _filterApp = appVal.ToString();
        if (query.TryGetValue("group", out var groupVal) && !string.IsNullOrWhiteSpace(groupVal))
        {
            _selectedGroupId = groupVal.ToString();
            var group = _groups.FirstOrDefault(g => g.Id == _selectedGroupId);
            if (group is not null && group.Files.Count > 0)
            {
                _selectedFileId = group.Files[0].FileName;
            }
        }
    }

    /// <summary>Navigates to the Request Files page (empty-state CTA).</summary>
    private void NavigateToRequestFiles()
        => Nav.NavigateTo("/soap/request-files");

    // ── Derived data ──

    private SoapExecutionGroup[] FilteredGroups
    {
        get
        {
            var query = _groups.AsEnumerable();

            if (!string.IsNullOrWhiteSpace(_filterFile))
                query = query.Where(g => g.Files.Any(f => f.FileName == _filterFile));
            if (!string.IsNullOrWhiteSpace(_filterApp))
                query = query.Where(g => g.Files.Any(f => f.AppName == _filterApp));
            if (!string.IsNullOrWhiteSpace(_filterStatus))
                query = query.Where(g => g.Status == _filterStatus);
            if (_filterDateFrom.HasValue)
                query = query.Where(g => TryParseTimestamp(g.StartedAt, out var dt) && dt >= _filterDateFrom.Value);
            if (_filterDateTo.HasValue)
                query = query.Where(g => TryParseTimestamp(g.StartedAt, out var dt) && dt <= _filterDateTo.Value);

            if (!string.IsNullOrWhiteSpace(_searchText))
            {
                var q = _searchText.ToLower();
                query = query.Where(g =>
                    g.Id.ToLower().Contains(q) ||
                    g.TriggeredBy.ToLower().Contains(q) ||
                    g.AppsSummary.ToLower().Contains(q) ||
                    g.Files.Any(f => f.FileName.ToLower().Contains(q) || f.Operation.ToLower().Contains(q)));
            }

            query = (_sortColumn, _sortAscending) switch
            {
                ("Id", true) or (null, _) => query.OrderBy(g => g.Id),
                ("Id", false) => query.OrderByDescending(g => g.Id),
                ("StartedAt", true) => query.OrderBy(g => g.StartedAt),
                ("StartedAt", false) => query.OrderByDescending(g => g.StartedAt),
                ("Applications", true) => query.OrderBy(g => g.AppsSummary),
                ("Applications", false) => query.OrderByDescending(g => g.AppsSummary),
                ("Files", true) => query.OrderBy(g => g.FileCount),
                ("Files", false) => query.OrderByDescending(g => g.FileCount),
                ("Status", true) => query.OrderBy(g => g.Status),
                ("Status", false) => query.OrderByDescending(g => g.Status),
                ("Duration", true) => query.OrderBy(g => g.DurationMs),
                ("Duration", false) => query.OrderByDescending(g => g.DurationMs),
                ("Triggered By", true) => query.OrderBy(g => g.TriggeredBy),
                ("Triggered By", false) => query.OrderByDescending(g => g.TriggeredBy),
                _ => query.OrderByDescending(g => g.StartedAt)
            };

            return [.. query];
        }
    }

    private SoapExecutionGroup? SelectedGroup =>
        _groups.FirstOrDefault(g => g.Id == _selectedGroupId);

    private SoapExecutionFile? SelectedFile =>
        SelectedGroup?.Files.FirstOrDefault(f => f.FileName == _selectedFileId)
        ?? SelectedGroup?.Files.FirstOrDefault();

    private string[] AvailableApps => [.. AppStore.Apps.Select(a => a.Name).OrderBy(n => n)];

    // ── Selection handlers ──

    private void SelectGroup(string groupId)
    {
        _selectedGroupId = groupId;
        var group = _groups.FirstOrDefault(g => g.Id == groupId);
        _selectedFileId = group is { Files.Count: > 0 } ? group.Files[0].FileName : null;
    }

    private void SelectFile(string fileName)
        => _selectedFileId = fileName;

    private void ClearSelection()
    {
        _selectedGroupId = null;
        _selectedFileId = null;
    }

    // ── Filter helpers ──

    private void OnFilterApplied() => _currentPage = 1;

    private void ResetFilters()
    {
        _filterFile = "";
        _filterApp = "";
        _filterStatus = "";
        _filterDateFrom = null;
        _filterDateTo = null;
        _currentPage = 1;
    }

    // ── Display helpers ──

    private static (string Css, string Label) GetStatusBadge(string status) => status switch
    {
        "running" => ("status-warn", "Running"),
        "completed" => ("status-enabled", "Completed"),
        "failed" => ("status-down", "Failed"),
        "partial" => ("status-warn", "Partial"),
        _ => ("status-disabled", status)
    };

    private static (string Css, string Label) GetFileStatusBadge(string status) => status switch
    {
        "success" => ("status-enabled", "Success"),
        "failed" => ("status-down", "Failed"),
        "running" => ("status-warn", "Running"),
        _ => ("status-disabled", "Queued")
    };

    private static string FormatDuration(long ms)
        => ms < 1000 ? $"{ms} ms" : $"{ms / 1000.0:0.0}s";

    private static bool TryParseTimestamp(string value, out DateTime dt)
        => DateTime.TryParse(value, out dt);
}
