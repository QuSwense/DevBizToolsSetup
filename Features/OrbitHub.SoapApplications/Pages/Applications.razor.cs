using System.Text.Json;
using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Rendering;
using Microsoft.JSInterop;
using OrbitHub.Common;
using OrbitHub.Common.Helpers;
using OrbitHub.Grid.Components;
using OrbitHub.SoapApplications.Core.Enums;
using OrbitHub.SoapApplications.Models;

namespace OrbitHub.SoapApplications.Pages;

public partial class Applications : IDisposable
{
    [Inject]
    private Microsoft.Extensions.Configuration.IConfiguration Config { get; set; } = default!;

    [Inject]
    private IJSRuntime JS { get; set; } = default!;

    private string CurrentUser => Config["Users:CurrentUser"] ?? "Current User";

    // ── Skeleton loading renderer ──
    private RenderFragment RenderSkeletonRows => builder =>
    {
        for (var i = 0; i < 5; i++)
        {
            builder.OpenElement(0, "div");
            builder.AddAttribute(1, "class", "skeleton-row");
            BuildSkeletonCell(builder, "skeleton-check");
            BuildSkeletonCell(builder, "skeleton-name", "w-70");
            BuildSkeletonCell(builder, "skeleton-url", "w-50");
            BuildSkeletonCell(builder, "skeleton-status", "w-60");
            BuildSkeletonCell(builder, "skeleton-updatedby", "w-50");
            BuildSkeletonCell(builder, "skeleton-date", "w-50");
            BuildSkeletonCell(builder, "skeleton-actions", "w-40");
            builder.CloseElement();
        }
    };

    private static void BuildSkeletonCell(RenderTreeBuilder builder, string cellClass, string? barClass = null)
    {
        builder.OpenElement(0, "div");
        builder.AddAttribute(1, "class", $"skeleton-cell {cellClass}");
        if (barClass is not null)
        {
            builder.OpenElement(2, "div");
            builder.AddAttribute(3, "class", $"skeleton-bar {barClass}");
            builder.CloseElement();
        }
        builder.CloseElement();
    }

    private List<GridColumn<SoapApp>> _columns = [];

    // ── Loading / Error State ──
    private bool _isLoading = true;
    private bool _hasError;
    private string? _errorMessage;
    private SoapApp[] _allApps = [];

    private string _searchText = "";
    private string _filterName = "";
    private string _filterUrl = "";
    private string _filterStatus = "";
    private string _filterUpdatedBy = "";
    private DateTime? _filterUpdatedDateFrom;
    private DateTime? _filterUpdatedDateTo;
    private DateTime? _filterCreatedDateFrom;
    private DateTime? _filterCreatedDateTo;
    private string _filterOperations = "";
    private int _currentPage = 1;
    private bool _showFilterModal = false;
    private bool _showAddModal = false;
    private List<string> _validationErrors = [];
    private string _newAppName = "";
    private string _newAppUrl = "";
    private string _newAppWsdlPath = "";
    private string _newAppDescription = "";
    private AppStatus _newAppStatus = AppStatus.Enabled;
    private SoapAuthConfig _newAuth = new() { Type = AuthType.Basic };
    private List<SoapApiEntry> _newApis = [];
    private bool _showDropdown = false;
    private HashSet<string> _expandedActionRows = [];
    private HashSet<string> _selectedIds = [];
    private SoapApp? _editingApp = null;
    private string _sortColumn = "";
    private bool _sortAscending = true;
    private ServiceHubGrid<SoapApp>? _grid;
    private string? _toastMessage;
    private string _toastType = "success";
    private CancellationTokenSource? _toastCts;


    protected override async Task OnInitializedAsync()
    {
        await base.OnInitializedAsync();
        _columns =
        [
            new()
            {
                Title = "App Name",
                Sortable = true,
                Field = a => a.Name,
                Template = context => builder =>
                {
                    var app = context;
                    var initials = app.Name.Length >= 2 ? app.Name[..2].ToUpper() : app.Name.ToUpper();
                    builder.OpenElement(0, "div");
                    builder.AddAttribute(1, "class", "name-stack");
                    builder.OpenElement(2, "span");
                    builder.AddAttribute(3, "class", "avatar-sm");
                    builder.AddContent(4, initials);
                    builder.CloseElement();
                    builder.OpenElement(5, "span");
                    builder.AddAttribute(6, "style", "font-weight:500");
                    builder.AddContent(7, app.Name);
                    builder.CloseElement();
                    builder.CloseElement();
                }
            },
            new()
            {
                Title = "Base URL",
                Sortable = true,
                Field = a => a.BaseUrl,
                Template = context => builder =>
                {
                    builder.OpenElement(0, "span");
                    builder.AddAttribute(1, "class", "cell-id");
                    builder.AddContent(2, context.BaseUrl);
                    builder.CloseElement();
                }
            },
            new()
            {
                Title = "Status",
                Sortable = true,
                Field = a => a.Status,
                Template = context => builder =>
                {
                    var badgeClass = context.Status == AppStatus.Enabled ? "status-enabled" : "status-disabled";
                    var label = context.Status == AppStatus.Enabled ? "Enabled" : "Disabled";
                    builder.OpenElement(0, "span");
                    builder.AddAttribute(1, "class", $"status-badge {badgeClass}");
                    builder.AddContent(2, label);
                    builder.CloseElement();
                }
            },
            new() { Title = "Last Updated", Sortable = true, Field = a => $"{a.UpdatedBy} ({(a.UpdatedAt.HasValue ? a.UpdatedAt.Value.ToString("yyyy-MM-dd") : "—")})" },
            new() { Title = "Created", Sortable = true, Field = a => $"{a.CreatedBy} ({a.CreatedAt:yyyy-MM-dd})" },
            new() { Title = "Operations", Sortable = true, Field = a => a.Apis.Length }
        ];

        await LoadAppsAsync();
    }

    // ── Data Loading ──

    private async Task LoadAppsAsync()
    {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
        try
        {
            // Simulate network/server delay so the loading skeleton is visible
            await Task.Delay(1000);

            _allApps = _appStore.Apps;
        }
        catch (Exception ex)
        {
            _hasError = true;
            _errorMessage = $"Failed to load applications: {ex.Message}";
        }
        finally
        {
            _isLoading = false;
        }
    }

    private void DismissError()
    {
        _hasError = false;
        _errorMessage = null;
    }

    private SoapApp[] FilteredApps
    {
        get
        {
            var query = _allApps.AsEnumerable();

            if (!string.IsNullOrWhiteSpace(_searchText))
            {
                var q = _searchText.ToLower();
                query = query.Where(a =>
                    a.Name.ToLower().Contains(q) ||
                    a.BaseUrl.ToLower().Contains(q) ||
                    (a.UpdatedBy ?? "").ToLower().Contains(q) ||
                    a.Status.ToString().ToLowerInvariant().Contains(q));
            }

            if (!string.IsNullOrWhiteSpace(_filterName))
                query = query.Where(a => a.Name.ToLower().Contains(_filterName.ToLower()));
            if (!string.IsNullOrWhiteSpace(_filterUrl))
                query = query.Where(a => a.BaseUrl.ToLower().Contains(_filterUrl.ToLower()));
            if (!string.IsNullOrWhiteSpace(_filterStatus) && Enum.TryParse<AppStatus>(_filterStatus, true, out var statusFilter))
                query = query.Where(a => a.Status == statusFilter);
            if (!string.IsNullOrWhiteSpace(_filterUpdatedBy))
                query = query.Where(a => a.UpdatedBy != null && 
                             a.UpdatedBy.Contains(_filterUpdatedBy, StringComparison.CurrentCultureIgnoreCase));
            if (_filterUpdatedDateFrom.HasValue)
                query = query.Where(a => a.UpdatedAt.HasValue && a.UpdatedAt.Value >= _filterUpdatedDateFrom.Value);
            if (_filterUpdatedDateTo.HasValue)
                query = query.Where(a => a.UpdatedAt.HasValue && a.UpdatedAt.Value <= _filterUpdatedDateTo.Value);
            if (_filterCreatedDateFrom.HasValue)
                query = query.Where(a => a.CreatedAt >= _filterCreatedDateFrom.Value);
            if (_filterCreatedDateTo.HasValue)
                query = query.Where(a => a.CreatedAt <= _filterCreatedDateTo.Value);
            if (!string.IsNullOrWhiteSpace(_filterOperations) && int.TryParse(_filterOperations, out var ops))
                query = query.Where(a => a.Apis.Length == ops);

            if (!string.IsNullOrWhiteSpace(_sortColumn))
            {
                query = _sortColumn switch
                {
                    "Name" => _sortAscending ? query.OrderBy(a => a.Name) : query.OrderByDescending(a => a.Name),
                    "BaseUrl" => _sortAscending ? query.OrderBy(a => a.BaseUrl) : query.OrderByDescending(a => a.BaseUrl),
                    "Status" => _sortAscending ? query.OrderBy(a => a.Status) : query.OrderByDescending(a => a.Status),
                    "UpdatedBy" => _sortAscending ? query.OrderBy(a => a.UpdatedBy) : query.OrderByDescending(a => a.UpdatedBy),
                    "CreatedDate" => _sortAscending ? query.OrderBy(a => a.CreatedAt) : query.OrderByDescending(a => a.CreatedAt),
                    "ApisCount" => _sortAscending ? query.OrderBy(a => a.Apis.Length) : query.OrderByDescending(a => a.Apis.Length),
                    _ => query
                };
            }

            return query.ToArray();
        }
    }

    private void OnFilterApplied()
    {
        _currentPage = 1;
    }

    private void OpenEditDialog(SoapApp app)
    {
        _editingApp = app;
        _newAppName = app.Name;
        _newAppUrl = app.BaseUrl;
        _newAppWsdlPath = app.WsdlPath;
        _newAppDescription = app.Description;
        _newAppStatus = app.Status;
        _newAuth = new SoapAuthConfig
        {
            Type = app.Auth.Type,
            Username = app.Auth.Username,
            Password = app.Auth.Password,
            KeyName = app.Auth.KeyName,
            KeyValue = app.Auth.KeyValue,
            Token = app.Auth.Token,
            Domain = app.Auth.Domain
        };
        _newApis = [..app.Apis];
        _expandedActionRows.Remove(app.Id);
        _validationErrors = [];
        _showAddModal = true;
    }

    private void OnActionRowClosed(string rowId)
    {
        _expandedActionRows.Remove(rowId);
        StateHasChanged();
    }

    private void HandleAddApplication()
    {
        _validationErrors = [];

        if (string.IsNullOrWhiteSpace(_newAppName))
        {
            _validationErrors.Add("App name is required.");
        }
        else if (!NamingConventionValidator.IsValidAppName(_newAppName))
        {
            _validationErrors.Add("App name may only contain letters (incl. German characters ä ö ü ß), digits and spaces.");
        }

        if (string.IsNullOrWhiteSpace(_newAppUrl))
        {
            _validationErrors.Add("Base URL is required.");
        }
        else if (!Uri.TryCreate(_newAppUrl.Trim(), UriKind.Absolute, out var url)
             || (url.Scheme != Uri.UriSchemeHttp && url.Scheme != Uri.UriSchemeHttps)
             || string.IsNullOrEmpty(url.Host))
        {
            _validationErrors.Add("Base URL must be a valid absolute http(s) URL, e.g. https://example.com/service.");
        }

        if (string.IsNullOrWhiteSpace(_newAppWsdlPath))
        {
            _validationErrors.Add("WSDL path is required.");
        }
        else if (_newAppWsdlPath.Contains("http", StringComparison.OrdinalIgnoreCase)
             || _newAppWsdlPath.Contains("://")
             || !NamingConventionValidator.IsValidWsdlPath(_newAppWsdlPath))
        {
            _validationErrors.Add("WSDL path must be a partial path (e.g. '?wsdl', '/service?wsdl') and must not contain a URL.");
        }

        if (_newApis.Count == 0)
        {
            _validationErrors.Add("At least one SOAP API must be added.");
        }
        else
        {
            foreach (var api in _newApis)
            {
                var name = api.Name.Trim();
                if (!NamingConventionValidator.IsValidCSharpIdentifier(name))
                {
                    _validationErrors.Add($"API name '{api.Name}' is not a valid C# method name.");
                }
            }
        }

        if (_validationErrors.Count > 0)
            return;

        if (_editingApp is not null)
        {
            var updatedApp = new SoapApp(
                _editingApp.Id,
                _newAppName.Trim(),
                _newAppUrl.Trim(),
                _newAppWsdlPath.Trim(),
                _newAppDescription.Trim(),
                _newAppStatus,
                _editingApp.CreatedBy,
                _editingApp.CreatedAt,
                _editingApp.UpdatedBy,
                _editingApp.UpdatedAt,
                BuildAuthConfig(),
                [.._newApis]
            );
            _appStore.UpdateApps([.._appStore.Apps.Where(a => a.Id != _editingApp.Id), updatedApp]);
        }
        else
        {
            var newId = $"s{_appStore.Apps.Length + 1}";
            var newApp = new SoapApp(
                newId,
                _newAppName.Trim(),
                _newAppUrl.Trim(),
                _newAppWsdlPath.Trim(),
                _newAppDescription.Trim(),
                _newAppStatus,
                CurrentUser,
                DateTime.Now,
                null,
                null,
                BuildAuthConfig(),
                [.._newApis]
            );
            _appStore.UpdateApps([.._appStore.Apps, newApp]);
        }

        _showAddModal = false;
        _editingApp = null;
        ResetAddForm();
        _currentPage = 1;
    }

    private void AddApiEntry()
    {
        _newApis.Add(new SoapApiEntry());
    }

    private void RemoveApiEntry(int index)
    {
        _newApis.RemoveAt(index);
    }

    private void ResetAddForm()
    {
        _validationErrors = [];
        _newAppName = "";
        _newAppUrl = "";
        _newAppWsdlPath = "";
        _newAppDescription = "";
        _newAppStatus = AppStatus.Enabled;
        _newAuth = new SoapAuthConfig { Type = AuthType.Basic };
        _newApis = [];
    }

    /// <summary>
    /// Builds a <see cref="SoapAuthConfig"/> from the current form state,
    /// populating only the fields relevant to the selected <see cref="AuthType"/>.
    /// </summary>
    private SoapAuthConfig BuildAuthConfig()
    {
        var auth = new SoapAuthConfig { Type = _newAuth.Type };
        switch (_newAuth.Type)
        {
            case AuthType.Basic:
                auth.Username = _newAuth.Username?.Trim();
                auth.Password = _newAuth.Password?.Trim();
                break;
            case AuthType.ApiKey:
                auth.KeyName = _newAuth.KeyName?.Trim();
                auth.KeyValue = _newAuth.KeyValue?.Trim();
                break;
            case AuthType.Bearer:
                auth.Token = _newAuth.Token?.Trim();
                break;
            case AuthType.Ntlm:
                auth.Username = _newAuth.Username?.Trim();
                auth.Password = _newAuth.Password?.Trim();
                auth.Domain = _newAuth.Domain?.Trim();
                break;
            case AuthType.None:
                break;
        }
        return auth;
    }

    private void HandleResetSort()
    {
        _showDropdown = false;
        _sortColumn = "";
        _sortAscending = true;
        _currentPage = 1;
    }

    private void ResetAdvancedFilters()
    {
        _searchText = "";
        _filterName = "";
        _filterUrl = "";
        _filterStatus = "";
        _filterUpdatedBy = "";
        _filterUpdatedDateFrom = null;
        _filterUpdatedDateTo = null;
        _filterCreatedDateFrom = null;
        _filterCreatedDateTo = null;
        _filterOperations = "";
        _currentPage = 1;
    }

    // ── Context Menu ──

    private Task<List<ContextMenuItem>> GetAppContextMenuItems(SoapApp app)
    {
        var isEnabled = app.Status == AppStatus.Enabled;
        return Task.FromResult(new List<ContextMenuItem>
        {
            new() { Action = "view", Label = "View Details", Icon = "bi-eye" },
            new() { Action = "edit", Label = "Edit", Icon = "bi-pencil" },
            new() { Action = "toggle", Label = isEnabled ? "Disable" : "Enable", Icon = isEnabled ? "bi-toggle-off" : "bi-toggle-on" },
            new() { Type = "divider" },
            new() { Action = "copyJson", Label = "Copy Row as JSON", Icon = "bi-braces" },
            new() { Action = "copyCsv", Label = "Copy Row as CSV", Icon = "bi-filetype-csv" },
            new() { Type = "divider" },
            new() { Action = "delete", Label = "Delete", Icon = "bi-trash", Danger = true }
        });
    }

    private async Task HandleContextMenuAction((string action, SoapApp app) e)
    {
        switch (e.action)
        {
            case "view":
                _grid?.ExpandRow(e.app.Id);
                break;
            case "edit":
                OpenEditDialog(e.app);
                break;
            case "toggle":
                ToggleAppStatus(e.app);
                break;
            case "delete":
                await DeleteAppAsync(e.app);
                break;
            case "copyJson":
                await CopyRowAsync(e.app, asCsv: false);
                break;
            case "copyCsv":
                await CopyRowAsync(e.app, asCsv: true);
                break;
        }
    }

    private void ToggleAppStatus(SoapApp app)
    {
        var newStatus = app.Status == AppStatus.Enabled ? AppStatus.Disabled : AppStatus.Enabled;
        var updated = app with
        {
            Status = newStatus,
            UpdatedBy = CurrentUser,
            UpdatedAt = DateTime.Now
        };
        _appStore.UpdateApps([.._appStore.Apps.Select(a => a.Id == app.Id ? updated : a)]);
        _allApps = _appStore.Apps;
        ShowToast(newStatus == AppStatus.Enabled ? "Application enabled" : "Application disabled");
    }

    private async Task DeleteAppAsync(SoapApp app)
    {
        // Request files are not yet backed by a database table — previously counted from
        // mock JSON. TODO: count from MSSQL (SoapRequestFiles) once the schema exists.
        var fileCount = 0;
        var testCaseCount = _testCaseStore.TestCases.Count(t => t.AppName == app.Name);
        var wsdlRecordCount = _wsdlStore.Records.Count(r => r.AppId == app.Id);

        var message = $"Delete application '{app.Name}'? This will also remove {fileCount} request file(s), " +
                      $"{testCaseCount} test case(s) and {wsdlRecordCount} WSDL sync record(s). " +
                      "Historical executions remain. This cannot be undone.";
        var confirmed = await JS.InvokeAsync<bool>("confirm", message);
        if (!confirmed) return;

        await CascadeDeleteAppAsync(app);
        _appStore.UpdateApps([.._appStore.Apps.Where(a => a.Id != app.Id)]);
        _allApps = _appStore.Apps;
        _expandedActionRows.Remove(app.Id);
        if (_editingApp?.Id == app.Id)
        {
            _showAddModal = false;
            _editingApp = null;
        }
        ShowToast("Application deleted", "danger");
    }

    /// <summary>
    /// Removes the application's dependent data: request files (persisted), test
    /// cases (persisted) and WSDL sync records + versions. Execution history is
    /// intentionally kept as a historical record.
    /// </summary>
    private async Task CascadeDeleteAppAsync(SoapApp app)
    {
        // Request files are not yet backed by a database table — previously deleted via
        // mock JSON. TODO: delete from MSSQL (SoapRequestFiles) once the schema exists.

        // Test cases
        var tcToRemove = _testCaseStore.TestCases.Where(t => t.AppName == app.Name).Select(t => t.Id).ToArray();
        foreach (var id in tcToRemove)
        {
            await _testCaseStore.DeleteTestCaseAsync(id);
        }

        // WSDL records + their versions
        var recordsToRemove = _wsdlStore.Records.Where(r => r.AppId == app.Id).Select(r => r.Id).ToArray();
        _wsdlStore.Records.RemoveAll(r => r.AppId == app.Id);
        _wsdlStore.Versions.RemoveAll(v => recordsToRemove.Contains(v.SyncRecordId));
    }

    private async Task CopyRowAsync(SoapApp app, bool asCsv)
    {
        try
        {
            var text = asCsv ? BuildCsvRow(app) : BuildJsonRow(app);
            await JS.InvokeVoidAsync("navigator.clipboard.writeText", text);
            ShowToast(asCsv ? "Row copied as CSV" : "Row copied as JSON");
        }
        catch
        {
            ShowToast("Copy failed — clipboard unavailable", "danger");
        }
    }

    /// <summary>Returns a copy of the app with secret auth values redacted.</summary>
    private static SoapApp ToRedacted(SoapApp app)
    {
        return app with
        {
            Auth = new SoapAuthConfig
            {
                Type = app.Auth.Type,
                Username = app.Auth.Username,
                Password = Redact(app.Auth.Password),
                KeyName = app.Auth.KeyName,
                KeyValue = Redact(app.Auth.KeyValue),
                Token = Redact(app.Auth.Token),
                Domain = app.Auth.Domain
            }
        };
    }

    /// <summary>Serializes the row as JSON, redacting secret auth values.</summary>
    private static string BuildJsonRow(SoapApp app)
        => JsonSerializer.Serialize(ToRedacted(app), new JsonSerializerOptions { WriteIndented = true });

    /// <summary>Builds a single CSV line from the safe (non-secret) row fields.</summary>
    private static string BuildCsvRow(SoapApp app)
    {
        var fields = new[]
        {
            CsvField(app.Id), CsvField(app.Name), CsvField(app.BaseUrl), CsvField(app.WsdlPath),
            CsvField(app.Description), CsvField(app.Status.ToString()),
            CsvField(app.CreatedBy), CsvField(app.CreatedAt.ToString("yyyy-MM-dd HH:mm")),
            CsvField(app.UpdatedBy ?? ""), CsvField(app.UpdatedAt?.ToString("yyyy-MM-dd HH:mm") ?? ""),
            CsvField(app.Apis.Length.ToString()), CsvField(app.Auth.Type.ToString())
        };
        return string.Join(",", fields);
    }

    private static string CsvField(string value) => CsvTextHelper.EncodeField(value);

    private static string? Redact(string? value) => string.IsNullOrEmpty(value) ? value : "***";

    // ── Export / Bulk Actions ──

    private async Task DownloadTextFileAsync(string content, string fileName, string mimeType)
    {
        try
        {
            var module = await JS.InvokeAsync<IJSObjectReference>("import", "./_content/OrbitHub.SoapApplications/js/download.js");
            try
            {
                await module.InvokeVoidAsync("downloadTextFile", content, fileName, mimeType);
            }
            finally
            {
                await module.DisposeAsync();
            }
        }
        catch
        {
            ShowToast("Export failed — file download unavailable", "danger");
        }
    }

    private async Task ExportToCsvAsync()
    {
        _showDropdown = false;
        var apps = FilteredApps;
        if (apps.Length == 0)
        {
            ShowToast("No data to export", "danger");
            return;
        }

        const string header = "Id,Name,BaseUrl,WsdlPath,Description,Status,CreatedBy,CreatedAt,UpdatedBy,UpdatedAt,ApisCount,AuthType";
        var lines = new List<string>(apps.Length + 1) { header };
        lines.AddRange(apps.Select(BuildCsvRow));
        await DownloadTextFileAsync(string.Join("\r\n", lines), "soap-applications.csv", "text/csv");
        ShowToast($"{apps.Length} application(s) exported as CSV");
    }

    private async Task ExportToJsonAsync()
    {
        _showDropdown = false;
        var apps = FilteredApps;
        if (apps.Length == 0)
        {
            ShowToast("No data to export", "danger");
            return;
        }

        var json = JsonSerializer.Serialize(apps.Select(ToRedacted).ToArray(), new JsonSerializerOptions { WriteIndented = true });
        await DownloadTextFileAsync(json, "soap-applications.json", "application/json");
        ShowToast($"{apps.Length} application(s) exported as JSON");
    }

    private async Task DeleteSelectedAsync()
    {
        _showDropdown = false;
        if (_selectedIds.Count == 0)
        {
            ShowToast("Select at least one application to delete", "danger");
            return;
        }

        var confirmed = await JS.InvokeAsync<bool>("confirm", $"Delete {_selectedIds.Count} selected application(s) and their request files, test cases and WSDL records? This cannot be undone.");
        if (!confirmed) return;

        var appsToDelete = _appStore.Apps.Where(a => _selectedIds.Contains(a.Id)).ToArray();
        foreach (var app in appsToDelete)
        {
            await CascadeDeleteAppAsync(app);
        }

        _appStore.UpdateApps([.._appStore.Apps.Where(a => !_selectedIds.Contains(a.Id))]);
        _allApps = _appStore.Apps;

        _expandedActionRows.RemoveWhere(_selectedIds.Contains);
        _selectedIds.Clear();
        if (_editingApp is not null && _allApps.All(a => a.Id != _editingApp.Id))
        {
            _showAddModal = false;
            _editingApp = null;
        }

        // PageSize is 5 (see ServiceHubGrid PageSize="5"); clamp to the new last page.
        var totalPages = Math.Max(1, (int)Math.Ceiling(FilteredApps.Length / 5.0));
        if (_currentPage > totalPages) _currentPage = totalPages;

        ShowToast("Selected application(s) deleted", "danger");
    }

    private void ExpandSelected()
    {
        _showDropdown = false;
        if (_selectedIds.Count == 0)
        {
            ShowToast("Select at least one row to expand", "danger");
            return;
        }
        _grid?.SetRowsExpanded(_selectedIds, expanded: true);
        ShowToast($"{_selectedIds.Count} row(s) expanded");
    }

    private void CollapseSelected()
    {
        _showDropdown = false;
        if (_selectedIds.Count == 0)
        {
            ShowToast("Select at least one row to collapse", "danger");
            return;
        }
        _grid?.SetRowsExpanded(_selectedIds, expanded: false);
        ShowToast($"{_selectedIds.Count} row(s) collapsed");
    }

    // ── Toast ──

    private void ShowToast(string message, string type = "success")
    {
        _toastMessage = message;
        _toastType = type;
        _toastCts?.Cancel();
        _toastCts = new CancellationTokenSource();
        var token = _toastCts.Token;
        _ = AutoDismissToastAsync(token);
        StateHasChanged();
    }

    private async Task AutoDismissToastAsync(CancellationToken token)
    {
        try
        {
            await Task.Delay(2500, token);
            if (!token.IsCancellationRequested)
            {
                _toastMessage = null;
                await InvokeAsync(StateHasChanged);
            }
        }
        catch (OperationCanceledException)
        {
        }
    }

    private void DismissToast()
    {
        _toastCts?.Cancel();
        _toastMessage = null;
    }

    public void Dispose()
    {
        _toastCts?.Cancel();
        _toastCts?.Dispose();
        GC.SuppressFinalize(this);
    }}
