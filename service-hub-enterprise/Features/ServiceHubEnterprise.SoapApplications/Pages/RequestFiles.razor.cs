using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Forms;
using Microsoft.AspNetCore.Components.Rendering;
using ServiceHubEnterprise.Grid.Components;
using ServiceHubEnterprise.SoapApplications.Models;
using ServiceHubEnterprise.SoapApplications.Services;

namespace ServiceHubEnterprise.SoapApplications.Pages;

public partial class RequestFiles
{
    [Inject]
    private Microsoft.Extensions.Configuration.IConfiguration Config { get; set; } = default!;

    private string CurrentUser => Config["Users:CurrentUser"] ?? "Current User";

    // ── Skeleton loading renderer ──
    private RenderFragment RenderSkeletonRows => builder =>
    {
        for (var i = 0; i < 5; i++)
        {
            builder.OpenElement(0, "div");
            builder.AddAttribute(1, "class", "skeleton-row");
            BuildSkeletonCell(builder, "skeleton-check");
            BuildSkeletonCell(builder, "skeleton-file-name", "w-70");
            BuildSkeletonCell(builder, "skeleton-app-name", "w-50");
            BuildSkeletonCell(builder, "skeleton-operation", "w-60");
            BuildSkeletonCell(builder, "skeleton-updated", "w-50");
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

    private record RequestFile(string FileName, string AppName, string ApiPath, string Verb, string Description, string Status, string CreatedBy, DateTime CreatedAt, string? UpdatedBy, DateTime? UpdatedAt);
    private class UploadFileEntry
    {
        public string FileName { get; set; } = "";
        public string Content { get; set; } = "";
    }

    // ── Loading / Error State ──
    private bool _isLoading = true;
    private bool _hasError;
    private string? _errorMessage;

    private List<GridColumn<RequestFile>> _columns = [];
    private HashSet<string> _expandedActionRows = [];

    private bool _showUploadModal = false;
    private string _uploadAppName = "";
    private string _uploadApiPath = "";
    private string _uploadDescription = "";
    private List<UploadFileEntry> _uploadFiles = [];
    private List<string> _validationErrors = [];
    private int _currentPage = 1;
    private bool _showFilterModal = false;
    private bool _showDropdown = false;
    private string _sortColumn = "";
    private bool _sortAscending = true;
    private string _searchText = "";
    private string _filterFileName = "";
    private string _filterAppName = "";
    private string _filterOperation = "";
    private string _filterVerb = "";
    private string _filterStatus = "";
    private string _filterCreatedBy = "";
    private string _filterUpdatedBy = "";
    private DateTime? _filterUpdatedDateFrom;
    private DateTime? _filterUpdatedDateTo;
    private DateTime? _filterCreatedDateFrom;
    private DateTime? _filterCreatedDateTo;

    private string[] _availableApps => _appStore.Apps.Select(a => a.Name).OrderBy(a => a).ToArray();
    private SoapApiEntry[] _availableOperations =>
        _appStore.Apps.FirstOrDefault(a => a.Name == _uploadAppName)?.Apis ?? [];

    private RequestFile[] _files = [];

    private static string GetVerbFromOperation(string operationName)
    {
        if (string.IsNullOrWhiteSpace(operationName))
            return "POST";
        var name = operationName.Trim();
        if (name.StartsWith("Get", StringComparison.OrdinalIgnoreCase) ||
            name.StartsWith("Find", StringComparison.OrdinalIgnoreCase) ||
            name.StartsWith("Search", StringComparison.OrdinalIgnoreCase) ||
            name.StartsWith("List", StringComparison.OrdinalIgnoreCase) ||
            name.StartsWith("Check", StringComparison.OrdinalIgnoreCase) ||
            name.StartsWith("Validate", StringComparison.OrdinalIgnoreCase) ||
            name.StartsWith("Track", StringComparison.OrdinalIgnoreCase) ||
            name.StartsWith("Export", StringComparison.OrdinalIgnoreCase))
            return "GET";
        return "POST";
    }

    protected override void OnInitialized()
    {
        _columns =
        [
            new()
            {
                Title = "File Name",
                Sortable = true,
                Field = f => f.FileName,
                Template = context => builder =>
                {
                    builder.OpenElement(0, "span");
                    builder.AddAttribute(1, "class", "mono-text");
                    builder.AddContent(2, context.FileName);
                    builder.CloseElement();
                }
            },
            new()
            {
                Title = "Application",
                Sortable = true,
                Field = f => f.AppName,
                Template = context => builder =>
                {
                    builder.OpenElement(0, "span");
                    builder.AddAttribute(1, "class", "text-sh-soft");
                    builder.AddContent(2, context.AppName);
                    builder.CloseElement();
                }
            },
            new()
            {
                Title = "Operation",
                Sortable = true,
                Field = f => f.ApiPath,
                Template = context => builder =>
                {
                    builder.OpenElement(0, "span");
                    builder.AddAttribute(1, "class", "cell-id");
                    builder.AddContent(2, context.ApiPath);
                    builder.CloseElement();
                }
            },
            new()
            {
                Title = "Status",
                Sortable = true,
                Field = f => f.Status,
                Template = context => builder =>
                {
                    var badgeClass = context.Status == "active" ? "status-enabled" : "status-disabled";
                    var label = context.Status == "active" ? "Active" : "Inactive";
                    builder.OpenElement(0, "span");
                    builder.AddAttribute(1, "class", $"status-badge {badgeClass}");
                    builder.AddContent(2, label);
                    builder.CloseElement();
                }
            },
            new()
            {
                Title = "Updated",
                Sortable = true,
                Field = f => $"{f.UpdatedBy} ({(f.UpdatedAt.HasValue ? f.UpdatedAt.Value.ToString("yyyy-MM-dd") : "—")})",
                Template = context => builder =>
                {
                    builder.OpenElement(0, "span");
                    builder.AddAttribute(1, "class", "text-sh-soft");
                    builder.AddContent(2, context.UpdatedAt.HasValue ? context.UpdatedAt.Value.ToString("yyyy-MM-dd") : "—");
                    builder.CloseElement();
                }
            }
        ];
    }

    protected override async Task OnInitializedAsync()
    {
        await base.OnInitializedAsync();
        await LoadFilesAsync();
    }

    // ── Data Loading ──

    private async Task LoadFilesAsync()
    {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
        try
        {
            // Simulate network/server delay so the loading skeleton is visible
            await Task.Delay(1500);

            _files = await _mockDbLoader.LoadJsonAsync<RequestFile[]>("request-files.json");
        }
        catch (Exception ex)
        {
            _hasError = true;
            _errorMessage = $"Failed to load request files: {ex.Message}";
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

    private void AddUploadFileEntry()
    {
        _uploadFiles = [.._uploadFiles, new UploadFileEntry()];
    }

    private void RemoveUploadFileEntry(int index)
    {
        _uploadFiles = [.._uploadFiles.Where((_, i) => i != index)];
    }

    private async Task HandleLocalFileUpload(InputFileChangeEventArgs e)
    {
        foreach (var file in e.GetMultipleFiles())
        {
            if (file.Size > 10 * 1024 * 1024)
                continue;

            using var stream = file.OpenReadStream(maxAllowedSize: 10 * 1024 * 1024);
            using var reader = new StreamReader(stream);
            var content = await reader.ReadToEndAsync();
            _uploadFiles = [.._uploadFiles, new UploadFileEntry { FileName = file.Name, Content = content }];
        }
    }

    private void HandleUploadFiles()
    {
        _validationErrors = [];

        if (string.IsNullOrWhiteSpace(_uploadAppName))
            _validationErrors.Add("Application is required.");
        if (string.IsNullOrWhiteSpace(_uploadApiPath))
            _validationErrors.Add("Operation is required.");

        var validFiles = _uploadFiles.Where(f => !string.IsNullOrWhiteSpace(f.FileName)).ToArray();
        if (validFiles.Length == 0)
            _validationErrors.Add("At least one file with a file name is required.");

        if (_validationErrors.Count > 0)
            return;

        var verb = GetVerbFromOperation(_uploadApiPath);
        var now = DateTime.Now;

        var newFiles = validFiles.Select(f => new RequestFile(
            f.FileName.Trim(),
            _uploadAppName.Trim(),
            _uploadApiPath.Trim(),
            verb,
            _uploadDescription.Trim(),
            "active",
            CurrentUser,
            now,
            null,
            null
        )).ToArray();

        _files = [.._files, ..newFiles];

        // Reset form
        _uploadAppName = "";
        _uploadApiPath = "";
        _uploadDescription = "";
        _uploadFiles = [];
        _showUploadModal = false;
    }

    private RequestFile[] FilteredFiles
    {
        get
        {
            var query = _files.AsEnumerable();

            if (!string.IsNullOrWhiteSpace(_searchText))
            {
                var q = _searchText.ToLower();
                query = query.Where(f =>
                    f.FileName.ToLower().Contains(q) ||
                    f.AppName.ToLower().Contains(q) ||
                    f.ApiPath.ToLower().Contains(q) ||
                    f.Verb.ToLower().Contains(q) ||
                    f.Description.ToLower().Contains(q));
            }

            if (!string.IsNullOrWhiteSpace(_filterFileName))
                query = query.Where(f => f.FileName.ToLower().Contains(_filterFileName.ToLower()));
            if (!string.IsNullOrWhiteSpace(_filterAppName))
                query = query.Where(f => f.AppName.ToLower().Contains(_filterAppName.ToLower()));
            if (!string.IsNullOrWhiteSpace(_filterOperation))
                query = query.Where(f => f.ApiPath.ToLower().Contains(_filterOperation.ToLower()));
            if (!string.IsNullOrWhiteSpace(_filterVerb))
                query = query.Where(f => f.Verb == _filterVerb);
            if (!string.IsNullOrWhiteSpace(_filterStatus))
                query = query.Where(f => f.Status == _filterStatus);
            if (!string.IsNullOrWhiteSpace(_filterCreatedBy))
                query = query.Where(f => f.CreatedBy.Contains(_filterCreatedBy, StringComparison.CurrentCultureIgnoreCase));
            if (!string.IsNullOrWhiteSpace(_filterUpdatedBy))
                query = query.Where(f => f.UpdatedBy != null && f.UpdatedBy.Contains(_filterUpdatedBy, StringComparison.CurrentCultureIgnoreCase));
            if (_filterUpdatedDateFrom.HasValue)
                query = query.Where(f => f.UpdatedAt.HasValue && f.UpdatedAt.Value >= _filterUpdatedDateFrom.Value);
            if (_filterUpdatedDateTo.HasValue)
                query = query.Where(f => f.UpdatedAt.HasValue && f.UpdatedAt.Value <= _filterUpdatedDateTo.Value);
            if (_filterCreatedDateFrom.HasValue)
                query = query.Where(f => f.CreatedAt >= _filterCreatedDateFrom.Value);
            if (_filterCreatedDateTo.HasValue)
                query = query.Where(f => f.CreatedAt <= _filterCreatedDateTo.Value);

            if (!string.IsNullOrWhiteSpace(_sortColumn))
            {
                query = _sortColumn switch
                {
                    "FileName" => _sortAscending ? query.OrderBy(f => f.FileName) : query.OrderByDescending(f => f.FileName),
                    "AppName" => _sortAscending ? query.OrderBy(f => f.AppName) : query.OrderByDescending(f => f.AppName),
                    "ApiPath" => _sortAscending ? query.OrderBy(f => f.ApiPath) : query.OrderByDescending(f => f.ApiPath),
                    "Status" => _sortAscending ? query.OrderBy(f => f.Status) : query.OrderByDescending(f => f.Status),
                    "Updated" => _sortAscending ? query.OrderBy(f => f.UpdatedAt) : query.OrderByDescending(f => f.UpdatedAt),
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
        _filterFileName = "";
        _filterAppName = "";
        _filterOperation = "";
        _filterVerb = "";
        _filterStatus = "";
        _filterCreatedBy = "";
        _filterUpdatedBy = "";
        _filterUpdatedDateFrom = null;
        _filterUpdatedDateTo = null;
        _filterCreatedDateFrom = null;
        _filterCreatedDateTo = null;
        _currentPage = 1;
    }
}
