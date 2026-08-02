using System.Text.Json;
using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Forms;
using Microsoft.AspNetCore.Components.Rendering;
using Microsoft.JSInterop;
using ServiceHubEnterprise.Grid.Components;
using ServiceHubEnterprise.SoapApplications.Core.Enums;
using ServiceHubEnterprise.SoapApplications.Models;
using ServiceHubEnterprise.SoapApplications.Services;
using ServiceHubEnterprise.SoapApplications.Services.Execution;

namespace ServiceHubEnterprise.SoapApplications.Pages;

public partial class RequestFiles : IDisposable
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

    private class UploadFileEntry
    {
        public string FileName { get; set; } = "";
        public string Content { get; set; } = "";
    }

    // ── Loading / Error State ──
    private bool _isLoading = true;
    private bool _hasError;
    private string? _errorMessage;

    private List<GridColumn<SoapRequestFile>> _columns = [];
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
    private SoapApiEntry[] EditAvailableOperations =>
        _appStore.Apps.FirstOrDefault(a => a.Name == _editAppName)?.Apis ?? [];

    /// <summary>
    /// Options rendered in the Edit dialog's Operation select. Includes the application's
    /// operations plus the file's currently saved operation when it is no longer part of
    /// the app's operation list, so the select always shows the bound value.
    /// </summary>
    private SoapApiEntry[] EditOperationOptions
    {
        get
        {
            var ops = EditAvailableOperations;
            if (string.IsNullOrWhiteSpace(_editApiPath))
            {
                return ops;
            }

            return ops.Any(o => o.Name == _editApiPath)
                ? ops
                : [.. ops, new SoapApiEntry { Name = _editApiPath, Description = "Previously selected operation" }];
        }
    }

    private SoapRequestFile[] _files = [];
    private ServiceHubGrid<SoapRequestFile>? _grid;
    private HashSet<string> _selectedIds = [];

    private bool _showEditModal = false;
    private SoapRequestFile? _editingFile = null;
    private string _editFileName = "";
    private string _editAppName = "";
    private string _editApiPath = "";
    private string _editDescription = "";
    private string _editStatus = "active";
    private List<string> _editValidationErrors = [];

    private string? _toastMessage;
    private string _toastType = "success";
    private CancellationTokenSource? _toastCts;

    // ── Execution state ──
    private bool _showExecutionProgress = false;
    private SoapExecutionGroup? _activeGroup;
    private bool _executionFinished = false;

    // ── Test-case management state ──
    private bool _showTestCasesModal = false;
    private SoapRequestFile? _tcFile;
    private SoapTestCase[] _fileTestCases = [];

    private bool _showTestCaseModal = false;
    private SoapTestCase? _editingTestCase;
    private string _tcName = "";
    private string _tcDescription = "";
    private bool _tcEnabled = true;
    private List<SoapExtractor> _tcExtractors = [];
    private List<string> _tcValidationErrors = [];

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

    /// <summary>
    /// Reads the simulated network delay for the loading skeleton from configuration
    /// (MockDb:RequestFilesDelayMs, default 1500). Tests set it to 0 for fast runs.
    /// </summary>
    private int GetRequestFilesDelayMs()
    {
        var raw = Config["MockDb:RequestFilesDelayMs"];
        return int.TryParse(raw, out var ms) ? ms : 1500;
    }

    private async Task LoadFilesAsync()
    {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
        try
        {
            // Simulate network/server delay so the loading skeleton is visible.
            // The delay is configurable (MockDb:RequestFilesDelayMs) so tests can run fast.
            var delayMs = GetRequestFilesDelayMs();
            if (delayMs > 0)
            {
                await Task.Delay(delayMs);
            }

            _files = await _mockDbLoader.LoadJsonAsync<SoapRequestFile[]>("Soap/Request/request-files.json");
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

    private void OnActionRowClosed(string rowId)
    {
        _expandedActionRows.Remove(rowId);
        StateHasChanged();
    }

    /// <summary>
    /// Navigates to the Applications page (used from the empty state when no
    /// applications exist yet).
    /// </summary>
    private void NavigateToApplications()
        => _nav.NavigateTo("/soap/applications");

    // ── Execution ──

    /// <summary>Executes a single request file (row action).</summary>
    private async Task ExecuteFileAsync(SoapRequestFile file)
        => await ExecuteFilesAsync([file]);

    /// <summary>Executes all selected request files (Actions dropdown).</summary>
    private async Task ExecuteSelectedAsync()
    {
        _showDropdown = false;
        var selected = _files.Where(f => _selectedIds.Contains(f.FileName)).ToArray();
        if (selected.Length == 0)
        {
            ShowToast("Select at least one request file to execute", "danger");
            return;
        }
        await ExecuteFilesAsync(selected);
    }

    /// <summary>
    /// Creates an execution group (unique id even for a single file), runs the
    /// simulated engine while showing per-file stage progress, persists the group
    /// and navigates to the Execute &amp; History page with the group selected.
    /// </summary>
    private async Task ExecuteFilesAsync(IReadOnlyList<SoapRequestFile> files)
    {
        if (files.Count == 0)
        {
            ShowToast("No request files to execute", "danger");
            return;
        }

        var blocked = files.Where(f =>
            _appStore.Apps.FirstOrDefault(a => a.Name == f.AppName)?.Status == AppStatus.Disabled).ToArray();
        if (blocked.Length > 0)
        {
            ShowToast($"Execution blocked — {blocked.Length} file(s) belong to a disabled application", "danger");
            return;
        }

        var group = _engine.CreateGroup(files, CurrentUser);
        _activeGroup = group;
        _executionFinished = false;
        _showExecutionProgress = true;

        var progress = new Progress<SoapExecutionGroup>(g =>
        {
            _activeGroup = g;
            _executionFinished = g.Status != "running";
            _ = InvokeAsync(StateHasChanged);
        });

        try
        {
            await _engine.RunAsync(group, progress);
        }
        finally
        {
            await _executionStore.AddGroupAsync(group);
            _showExecutionProgress = false;
            StateHasChanged();
        }

        ShowToast("Execution completed");
        _nav.NavigateTo($"/soap/execute-history?group={Uri.EscapeDataString(group.Id)}");
    }

    /// <summary>Navigates to the per-file execution history for a request file.</summary>
    private void NavigateToFileHistory(SoapRequestFile file)
        => _nav.NavigateTo($"/soap/execute-history?file={Uri.EscapeDataString(file.FileName)}&app={Uri.EscapeDataString(file.AppName)}");

    /// <summary>Navigates to the generic file editor for a request file.</summary>
    private void NavigateToEditor(SoapRequestFile file)
        => _nav.NavigateTo($"/file/editor?app={Uri.EscapeDataString(file.AppName)}&file={Uri.EscapeDataString(file.FileName)}");

    // ── Test cases ──

    /// <summary>Opens the test-case list modal for a request file.</summary>
    private void OpenTestCasesModal(SoapRequestFile file)
    {
        _tcFile = file;
        _fileTestCases = _testCaseStore.GetForFile(file.AppName, file.FileName).ToArray();
        _showTestCasesModal = true;
    }

    private void CloseTestCasesModal()
    {
        _showTestCasesModal = false;
        _tcFile = null;
    }

    private void OpenCreateTestCase()
    {
        _editingTestCase = null;
        _tcName = "";
        _tcDescription = "";
        _tcEnabled = true;
        _tcExtractors = [NewExtractor()];
        _tcValidationErrors = [];
        _showTestCaseModal = true;
    }

    private void OpenEditTestCase(SoapTestCase testCase)
    {
        _editingTestCase = testCase;
        _tcName = testCase.Name;
        _tcDescription = testCase.Description;
        _tcEnabled = testCase.Enabled;
        _tcExtractors = testCase.Extractors.Select(e => new SoapExtractor
        {
            Id = e.Id,
            Name = e.Name,
            Source = e.Source,
            Type = e.Type,
            Path = e.Path,
            ExpectedValue = e.ExpectedValue
        }).ToList();
        _tcValidationErrors = [];
        _showTestCaseModal = true;
    }

    private static SoapExtractor NewExtractor() => new()
    {
        Id = $"ex-{Guid.NewGuid():N}"[..10],
        Name = "",
        Source = "response",
        Type = "xpath",
        Path = ""
    };

    private void AddExtractor() => _tcExtractors.Add(NewExtractor());

    private void RemoveExtractor(int index) => _tcExtractors.RemoveAt(index);

    /// <summary>Validates and saves the test case being edited, then persists it.</summary>
    private async Task SaveTestCaseAsync()
    {
        _tcValidationErrors = [];
        if (_tcFile is null)
            return;

        if (string.IsNullOrWhiteSpace(_tcName))
        {
            _tcValidationErrors.Add("Test case name is required.");
        }
        else if (_testCaseStore.TestCases.Any(t =>
                     t.AppName == _tcFile.AppName &&
                     t.FileName == _tcFile.FileName &&
                     t.Name == _tcName.Trim() &&
                     t.Id != _editingTestCase?.Id))
        {
            _tcValidationErrors.Add("A test case with this name already exists for this request file.");
        }

        foreach (var ex in _tcExtractors)
        {
            if (string.IsNullOrWhiteSpace(ex.Name))
            {
                ex.Name = string.IsNullOrWhiteSpace(ex.Path) ? "extraction" : ex.Path;
            }
            if (string.IsNullOrWhiteSpace(ex.Path))
            {
                _tcValidationErrors.Add($"Extractor '{ex.Name}' requires a path/expression.");
            }
        }

        if (_tcValidationErrors.Count > 0)
            return;

        var now = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
        if (_editingTestCase is not null)
        {
            _editingTestCase.Name = _tcName.Trim();
            _editingTestCase.Description = _tcDescription.Trim();
            _editingTestCase.Enabled = _tcEnabled;
            _editingTestCase.Extractors = _tcExtractors;
            _editingTestCase.UpdatedBy = CurrentUser;
            _editingTestCase.UpdatedAt = now;
            await _testCaseStore.UpdateTestCaseAsync(_editingTestCase);
        }
        else
        {
            var testCase = new SoapTestCase
            {
                Id = $"tc-{Guid.NewGuid():N}"[..12],
                Name = _tcName.Trim(),
                Description = _tcDescription.Trim(),
                AppName = _tcFile.AppName,
                FileName = _tcFile.FileName,
                Enabled = _tcEnabled,
                CreatedBy = CurrentUser,
                CreatedAt = now,
                UpdatedBy = CurrentUser,
                UpdatedAt = now,
                Extractors = _tcExtractors
            };
            await _testCaseStore.AddTestCaseAsync(testCase);
        }

        _fileTestCases = _testCaseStore.GetForFile(_tcFile.AppName, _tcFile.FileName).ToArray();
        _showTestCaseModal = false;
        ShowToast(_editingTestCase is null ? "Test case created" : "Test case updated");
    }

    private async Task ToggleTestCase(SoapTestCase testCase)
    {
        testCase.Enabled = !testCase.Enabled;
        testCase.UpdatedBy = CurrentUser;
        testCase.UpdatedAt = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
        await _testCaseStore.UpdateTestCaseAsync(testCase);
        if (_tcFile is not null)
        {
            _fileTestCases = _testCaseStore.GetForFile(_tcFile.AppName, _tcFile.FileName).ToArray();
        }
    }

    private async Task DeleteTestCaseAsync(SoapTestCase testCase)
    {
        var confirmed = await JS.InvokeAsync<bool>("confirm", $"Delete test case '{testCase.Name}'?");
        if (!confirmed)
            return;
        await _testCaseStore.DeleteTestCaseAsync(testCase.Id);
        if (_tcFile is not null)
        {
            _fileTestCases = _testCaseStore.GetForFile(_tcFile.AppName, _tcFile.FileName).ToArray();
        }
        ShowToast("Test case deleted", "danger");
    }

    // ── Progress stage helpers ──

    private static string GetStageState(SoapExecutionFile file, ExecutionStage stage)
    {
        var index = (int)stage;
        if (file.StagesCompleted > index)
            return "done";
        if (file.Status is "success" or "failed")
            return "pending";
        return (int)file.Stage == index ? "active" : "pending";
    }

    private static string GetStageLabel(ExecutionStage stage) => stage switch
    {
        ExecutionStage.Queued => "Queued",
        ExecutionStage.BuildingRequest => "Building",
        ExecutionStage.SendingRequest => "Sending",
        ExecutionStage.AwaitingResponse => "Awaiting",
        ExecutionStage.ParsingResponse => "Parsing",
        ExecutionStage.RunningTestCases => "Tests",
        ExecutionStage.Complete => "Complete",
        _ => stage.ToString()
    };

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

    private async Task HandleUploadFiles()
    {
        _validationErrors = [];

        if (string.IsNullOrWhiteSpace(_uploadAppName))
            _validationErrors.Add("Application is required.");
        if (string.IsNullOrWhiteSpace(_uploadApiPath))
            _validationErrors.Add("Operation is required.");

        var validFiles = _uploadFiles.Where(f => !string.IsNullOrWhiteSpace(f.FileName)).ToArray();
        if (validFiles.Length == 0)
            _validationErrors.Add("At least one file with a file name is required.");

        // Duplicate-file validation (same application + file name).
        if (validFiles.Length > 0 && !string.IsNullOrWhiteSpace(_uploadAppName))
        {
            var batchDuplicates = validFiles
                .Select(f => f.FileName.Trim())
                .GroupBy(n => n, StringComparer.OrdinalIgnoreCase)
                .Where(g => g.Count() > 1)
                .Select(g => g.Key)
                .ToArray();
            if (batchDuplicates.Length > 0)
            {
                _validationErrors.Add($"Duplicate file name(s) in the upload batch: {string.Join(", ", batchDuplicates)}.");
            }

            var existing = _files
                .Where(f => f.AppName == _uploadAppName.Trim())
                .Select(f => f.FileName)
                .ToHashSet(StringComparer.OrdinalIgnoreCase);
            var existingDuplicates = validFiles
                .Select(f => f.FileName.Trim())
                .Where(existing.Contains)
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToArray();
            if (existingDuplicates.Length > 0)
            {
                _validationErrors.Add($"File(s) already exist for this application: {string.Join(", ", existingDuplicates)}.");
            }
        }

        if (_validationErrors.Count > 0)
            return;

        var verb = GetVerbFromOperation(_uploadApiPath);
        var now = DateTime.Now;

        var newFiles = validFiles.Select(f => new SoapRequestFile(
            f.FileName.Trim(),
            _uploadAppName.Trim(),
            _uploadApiPath.Trim(),
            verb,
            _uploadDescription.Trim(),
            "active",
            CurrentUser,
            now,
            null,
            null,
            f.Content
        )).ToArray();

        _files = [.._files, ..newFiles];

        // Reset form
        _uploadAppName = "";
        _uploadApiPath = "";
        _uploadDescription = "";
        _uploadFiles = [];
        _showUploadModal = false;

        await PersistFilesAsync();
        ShowToast($"{newFiles.Length} request file(s) uploaded");
    }

    // ── Persistence ──

    /// <summary>
    /// Persists the in-memory file list back to mock_db/Soap/Request/request-files.json.
    /// </summary>
    private async Task PersistFilesAsync()
    {
        try
        {
            await _mockDbLoader.SaveJsonAsync("Soap/Request/request-files.json", _files);
        }
        catch
        {
            ShowToast("Failed to save changes to the mock database", "danger");
        }
    }

    // ── Row Actions ──


    private void OpenEditDialog(SoapRequestFile file)
    {
        _editingFile = file;
        _editFileName = file.FileName;
        _editAppName = file.AppName;
        _editApiPath = file.ApiPath;
        _editDescription = file.Description;
        _editStatus = file.Status;
        _editValidationErrors = [];
        _expandedActionRows.Remove(file.FileName);
        _showEditModal = true;
    }

    private async Task SaveEditDialogAsync()
    {
        _editValidationErrors = [];
        if (string.IsNullOrWhiteSpace(_editFileName))
            _editValidationErrors.Add("File name is required.");
        if (string.IsNullOrWhiteSpace(_editAppName))
            _editValidationErrors.Add("Application is required.");
        if (string.IsNullOrWhiteSpace(_editApiPath))
            _editValidationErrors.Add("Operation is required.");
        else if (EditAvailableOperations.All(o => o.Name != _editApiPath))
            _editValidationErrors.Add("Operation must belong to the selected application.");

        if (!string.IsNullOrWhiteSpace(_editFileName) && !string.IsNullOrWhiteSpace(_editAppName))
        {
            var currentName = _editingFile?.FileName ?? "";
            var duplicate = _files.Any(f =>
                f.AppName == _editAppName.Trim() &&
                f.FileName == _editFileName.Trim() &&
                f.FileName != currentName);
            if (duplicate)
            {
                _editValidationErrors.Add("A request file with this name already exists for this application.");
            }
        }

        if (_editValidationErrors.Count > 0)
            return;

        var originalName = _editingFile?.FileName ?? "";
        var now = DateTime.Now;

        _files = [.._files.Select(f =>
            f.FileName == originalName
                ? new SoapRequestFile(
                    _editFileName.Trim(),
                    _editAppName.Trim(),
                    _editApiPath.Trim(),
                    GetVerbFromOperation(_editApiPath.Trim()),
                    _editDescription.Trim(),
                    _editStatus,
                    f.CreatedBy,
                    f.CreatedAt,
                    CurrentUser,
                    now,
                    f.Content)  // ← preserve content, don't drop
                : f)];

        _showEditModal = false;
        _editingFile = null;

        await PersistFilesAsync();
        ShowToast("Request file updated");
    }

    private async Task ToggleFileStatus(SoapRequestFile file)
    {
        var newStatus = file.Status == "active" ? "inactive" : "active";
        _files = [.._files.Select(f =>
            f.FileName == file.FileName
                ? f with { Status = newStatus, UpdatedBy = CurrentUser, UpdatedAt = DateTime.Now }
                : f)];

        await PersistFilesAsync();
        ShowToast(newStatus == "active" ? "Request file enabled" : "Request file disabled");
    }

    private async Task DeleteFileAsync(SoapRequestFile file)
    {
        var confirmed = await JS.InvokeAsync<bool>("confirm", $"Delete request file '{file.FileName}'? This cannot be undone.");
        if (!confirmed) return;

        _files = [.._files.Where(f => f.FileName != file.FileName)];
        _expandedActionRows.Remove(file.FileName);
        _selectedIds.Remove(file.FileName);

        await PersistFilesAsync();
        ShowToast("Request file deleted", "danger");
    }

    // ── Export / Bulk Actions ──

    private async Task DownloadTextFileAsync(string content, string fileName, string mimeType)
    {
        try
        {
            var module = await JS.InvokeAsync<IJSObjectReference>("import", "./_content/ServiceHubEnterprise.SoapApplications/js/download.js");
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
        var files = FilteredFiles;
        if (files.Length == 0)
        {
            ShowToast("No data to export", "danger");
            return;
        }

        const string header = "FileName,AppName,Operation,Verb,Description,Status,CreatedBy,CreatedAt,UpdatedBy,UpdatedAt";
        var lines = new List<string>(files.Length + 1) { header };
        lines.AddRange(files.Select(BuildCsvRow));
        await DownloadTextFileAsync(string.Join("\r\n", lines), "request-files.csv", "text/csv");
        ShowToast($"{files.Length} request file(s) exported as CSV");
    }

    private async Task ExportToJsonAsync()
    {
        _showDropdown = false;
        var files = FilteredFiles;
        if (files.Length == 0)
        {
            ShowToast("No data to export", "danger");
            return;
        }

        var json = JsonSerializer.Serialize(files, new JsonSerializerOptions { WriteIndented = true });
        await DownloadTextFileAsync(json, "request-files.json", "application/json");
        ShowToast($"{files.Length} request file(s) exported as JSON");
    }

    private static string BuildCsvRow(SoapRequestFile f)
    {
        var fields = new[]
        {
            CsvField(f.FileName), CsvField(f.AppName), CsvField(f.ApiPath), CsvField(f.Verb),
            CsvField(f.Description), CsvField(f.Status),
            CsvField(f.CreatedBy), CsvField(f.CreatedAt.ToString("yyyy-MM-dd HH:mm")),
            CsvField(f.UpdatedBy ?? ""), CsvField(f.UpdatedAt?.ToString("yyyy-MM-dd HH:mm") ?? "")
        };
        return string.Join(",", fields);
    }

    private static string CsvField(string value) => $"\"{(value ?? "").Replace("\"", "\"\"")}\"";

    private async Task DeleteSelectedAsync()
    {
        _showDropdown = false;
        if (_selectedIds.Count == 0)
        {
            ShowToast("Select at least one request file to delete", "danger");
            return;
        }

        var confirmed = await JS.InvokeAsync<bool>("confirm", $"Delete {_selectedIds.Count} selected request file(s)? This cannot be undone.");
        if (!confirmed) return;

        _files = [.._files.Where(f => !_selectedIds.Contains(f.FileName))];
        _expandedActionRows.RemoveWhere(_selectedIds.Contains);
        _selectedIds.Clear();

        // PageSize is 10 (see ServiceHubGrid PageSize="10"); clamp to the new last page.
        var totalPages = Math.Max(1, (int)Math.Ceiling(FilteredFiles.Length / 10.0));
        if (_currentPage > totalPages) _currentPage = totalPages;

        await PersistFilesAsync();
        ShowToast("Selected request file(s) deleted", "danger");
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
    }

    private SoapRequestFile[] FilteredFiles
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
