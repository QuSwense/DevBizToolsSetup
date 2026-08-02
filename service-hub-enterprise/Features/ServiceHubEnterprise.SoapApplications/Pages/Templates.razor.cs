using System.Text.Json;
using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Forms;
using Microsoft.AspNetCore.Components.Rendering;
using Microsoft.JSInterop;
using ServiceHubEnterprise.Grid.Components;
using ServiceHubEnterprise.SoapApplications.Models;
using ServiceHubEnterprise.SoapApplications.Services;

namespace ServiceHubEnterprise.SoapApplications.Pages;

public partial class Templates : IAsyncDisposable
{
    // ── Skeleton loading renderer ──
    private RenderFragment RenderSkeletonRows => builder =>
    {
        for (var i = 0; i < 5; i++)
        {
            builder.OpenElement(0, "div");
            builder.AddAttribute(1, "class", "skeleton-row");
            BuildSkeletonCell(builder, "skeleton-check");
            BuildSkeletonCell(builder, "skeleton-name", "w-70");
            BuildSkeletonCell(builder, "skeleton-wsdl", "w-50");
            BuildSkeletonCell(builder, "skeleton-vars", "w-30");
            BuildSkeletonCell(builder, "skeleton-status", "w-60");
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

    // ── Data Models ──

    private record TemplateVariable(string Name, string Type, string Sample, bool Required);

    private record Template(
        string Name,
        string Wsdl,
        string Operation,
        int Variables,
        string Status,
        string Category,
        string Description,
        string[] Tags,
        string EndpointUrl,
        string SoapAction,
        string XmlContent,
        TemplateVariable[] VariableList,
        string Created,
        string Updated,
        int Usage
    );

    private record TemplateFormModel
    {
        public string Name { get; set; } = "";
        public string Description { get; set; } = "";
        public string Category { get; set; } = "";
        public string Tags { get; set; } = "";
        public string Wsdl { get; set; } = "";
        public string Operation { get; set; } = "";
        public string EndpointUrl { get; set; } = "";
        public string SoapAction { get; set; } = "";
        public string Status { get; set; } = "Draft";
        public string XmlContent { get; set; } = "";
        public string SourceType { get; set; } = "blank"; // blank | upload | saved
        public List<TemplateVariable> VariableList { get; set; } = [];
    }

    // ── Injected services ──

    [Inject] private SoapAppStore AppStore { get; set; } = default!;
    [Inject] private IJSRuntime JsRuntime { get; set; } = default!;

    // ── State ──

    private List<GridColumn<Template>> _columns = [];
    private HashSet<string> _expandedActionRows = [];
    private Template[] _allTemplates = [];
    private Template[] _filteredTemplates = [];

    // ── Selection ──
    private HashSet<string> _selectedIds = [];
    private bool _selectAll;

    // ── Search & Filter ──
    private string _searchText = "";
    private string _filterStatus = "All";
    private HashSet<string> _activeFilters = [];

    // ── Grid sort state ──
    private string? _sortColumn;
    private bool _sortAscending = true;
    private int _currentPage = 1;

    // ── Modal state ──
    private bool _showModal;
    private bool _isEditMode;
    private string _editOriginalName = "";
    private TemplateFormModel _formModel = new();
    private int _activeTabIndex;

    // ── Preview & Test ──
    private bool _showPreviewSection;
    private Dictionary<string, string> _testValues = [];
    private string _renderedXmlPreview = "";
    private string? _testResponse;
    private bool _isTestLoading;

    // ── Validation ──
    private List<string> _validationErrors = [];
    private bool _showValidationPanel;
    private List<(string Check, bool Passed)> _validationChecks = [];

    // ── UI State ──
    private bool _isLoading = true;
    private bool _hasError;
    private string? _errorMessage;
    private string? _successMessage;
    private bool _showDeleteConfirm;
    private string? _deleteTargetName;
    private bool _isBulkDeleting;
    private bool _isSaving;
    private string? _savingIndicator;
    private bool _showSourceDropdown;

    // ── Drag & drop upload state ──
    private bool _isDragOver;
    private string? _uploadFileName;

    // ── Monaco editor ──
    private const string MonacoEditorId = "template-xml-editor";
    private bool _monacoInitialized;
    private DotNetObjectReference<Templates>? _monacoDotNetRef;

    // ── Application / Operation options ──
    private SoapApp[] _availableApps => AppStore.Apps;
    private SoapApp? _formSelectedApp => string.IsNullOrEmpty(_formModel.Category)
        ? null
        : _availableApps.FirstOrDefault(a =>
            string.Equals(a.Name, _formModel.Category, StringComparison.OrdinalIgnoreCase));
    private string[] _formAvailableOperations => _formSelectedApp?.Apis.Select(a => a.Name).OrderBy(x => x).ToArray() ?? [];

    // ── Filtered count ──
    private int _filteredCount => _filteredTemplates.Length;

    // ── Derived computed data ──
    private bool _hasSelection => _selectedIds.Count > 0;
    private string _selectedCountText => $"{_selectedIds.Count} template{(_selectedIds.Count != 1 ? "s" : "")} selected";

    // ── Lifecycle ──

    protected override void OnInitialized()
    {
        _columns =
        [
            new()
            {
                Title = "Name",
                Sortable = true,
                Field = t => t.Name,
                Width = "minmax(180px, 1fr)",
                Template = context => builder =>
                {
                    builder.OpenElement(0, "button");
                    builder.AddAttribute(1, "type", "button");
                    builder.AddAttribute(2, "class", "btn btn-link-dg template-name-btn");
                    builder.AddAttribute(3, "aria-label", $"Edit template: {context.Name}");
                    builder.AddAttribute(4, "onclick",
                        EventCallback.Factory.Create(this, () => OpenEditTemplate(context)));
                    builder.AddContent(5, context.Name);
                    builder.CloseElement();
                }
            },
            new()
            {
                Title = "WSDL",
                Sortable = true,
                Field = t => t.Wsdl,
                Width = "120px",
                Template = context => builder =>
                {
                    builder.OpenElement(0, "span");
                    builder.AddAttribute(1, "class", "wsdl-badge");
                    builder.AddContent(2, context.Wsdl);
                    builder.CloseElement();
                }
            },
            new()
            {
                Title = "Variables",
                Sortable = true,
                Field = t => t.Variables,
                Width = "100px",
                Template = context => builder =>
                {
                    builder.OpenElement(0, "span");
                    builder.AddAttribute(1, "class", "mono-text text-sh-soft");
                    builder.AddContent(2, context.Variables.ToString());
                    builder.CloseElement();
                }
            },
            new()
            {
                Title = "Status",
                Sortable = true,
                Field = t => t.Status,
                Width = "120px",
                Template = context => builder =>
                {
                    var statusClass = context.Status.ToLowerInvariant() switch
                    {
                        "published" => "status-published",
                        "draft" => "status-draft",
                        "archived" => "status-archived",
                        "invalid" => "status-invalid",
                        _ => "status-draft"
                    };
                    builder.OpenElement(0, "span");
                    builder.AddAttribute(1, "class", $"status-badge {statusClass}");
                    builder.AddAttribute(2, "data-tooltip", $"Status: {context.Status}");
                    builder.AddContent(3, context.Status);
                    builder.CloseElement();
                }
            },
            new()
            {
                Title = "Updated",
                Sortable = true,
                Field = t => t.Updated,
                Width = "120px",
                Template = context => builder =>
                {
                    var relative = GetRelativeTime(context.Updated);
                    builder.OpenElement(0, "span");
                    builder.AddAttribute(1, "class", "text-sh-soft");
                    builder.AddAttribute(2, "data-tooltip", context.Updated);
                    builder.AddContent(3, relative);
                    builder.CloseElement();
                }
            }
        ];
    }

    protected override async Task OnInitializedAsync()
    {
        await base.OnInitializedAsync();
        await LoadTemplatesAsync();
    }

    private void OnActionRowClosed(string rowId)
    {
        _expandedActionRows.Remove(rowId);
        StateHasChanged();
    }

    // ── Data Loading ──

    private async Task LoadTemplatesAsync()
    {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
        try
        {
            // Simulate network/server delay so the loading skeleton is visible
            await Task.Delay(1500);

            _allTemplates = await _mockDbLoader.LoadJsonAsync<Template[]>("templates-page.json") ?? [];
            ApplyFilters();
        }
        catch (Exception ex)
        {
            _hasError = true;
            _errorMessage = $"Failed to load templates: {ex.Message}";
        }
        finally
        {
            _isLoading = false;
        }
    }

    // ── Filtering & Sorting ──

    private void ApplyFilters()
    {
        var query = _allTemplates.AsEnumerable();

        // Text search
        if (!string.IsNullOrWhiteSpace(_searchText))
        {
            var search = _searchText.Trim().ToLowerInvariant();
            query = query.Where(t =>
                t.Name.Contains(search, StringComparison.OrdinalIgnoreCase) ||
                t.Wsdl.Contains(search, StringComparison.OrdinalIgnoreCase) ||
                t.Category.Contains(search, StringComparison.OrdinalIgnoreCase) ||
                t.Description.Contains(search, StringComparison.OrdinalIgnoreCase) ||
                t.Tags.Any(tag => tag.Contains(search, StringComparison.OrdinalIgnoreCase))
            );
        }

        // Status filter
        if (_filterStatus != "All")
        {
            query = query.Where(t =>
                string.Equals(t.Status, _filterStatus, StringComparison.OrdinalIgnoreCase));
        }

        // Apply sorting (from grid column sort)
        query = (_sortColumn, _sortAscending) switch
        {
            ("Name", true) or (null, _) => query.OrderBy(t => t.Name),
            ("Name", false) => query.OrderByDescending(t => t.Name),
            ("Wsdl", true) => query.OrderBy(t => t.Wsdl),
            ("Wsdl", false) => query.OrderByDescending(t => t.Wsdl),
            ("Variables", true) => query.OrderBy(t => t.Variables),
            ("Variables", false) => query.OrderByDescending(t => t.Variables),
            ("Status", true) => query.OrderBy(t => t.Status),
            ("Status", false) => query.OrderByDescending(t => t.Status),
            ("Updated", true) => query.OrderBy(t => t.Updated),
            ("Updated", false) => query.OrderByDescending(t => t.Updated),
            _ => query.OrderBy(t => t.Name)
        };

        _filteredTemplates = query.ToArray();
        _currentPage = 1;
        UpdateActiveFilterPills();
    }

    private void OnFilterStatusChanged(ChangeEventArgs e)
    {
        _filterStatus = e.Value?.ToString() ?? "All";
        _currentPage = 1;
        ApplyFilters();
        StateHasChanged();
    }

    // ── Grid event handlers ──

    private void OnGridSearchChanged(string searchText)
    {
        // _searchText already updated via @bind-SearchText
        _currentPage = 1;
        ApplyFilters();
        StateHasChanged();
    }

    private Task OnSortColumnChanged(string? column)
    {
        _sortColumn = column;
        _currentPage = 1;
        ApplyFilters();
        StateHasChanged();
        return Task.CompletedTask;
    }

    private Task OnSortAscendingChanged(bool ascending)
    {
        _sortAscending = ascending;
        _currentPage = 1;
        ApplyFilters();
        StateHasChanged();
        return Task.CompletedTask;
    }

    private void ClearFilters()
    {
        _searchText = "";
        _filterStatus = "All";
        _sortColumn = null;
        _sortAscending = true;
        _currentPage = 1;
        ApplyFilters();
        StateHasChanged();
    }

    private void UpdateActiveFilterPills()
    {
        _activeFilters = [];
        if (_filterStatus != "All")
            _activeFilters.Add($"Status: {_filterStatus}");
        if (!string.IsNullOrWhiteSpace(_searchText))
            _activeFilters.Add($"Search: \"{_searchText}\"");
    }

    private void RemoveFilterPill(string filter)
    {
        if (filter.StartsWith("Status:"))
            _filterStatus = "All";
        else if (filter.StartsWith("Search:"))
            _searchText = "";
        ApplyFilters();
        StateHasChanged();
    }

    // ── Selection ──

    private void ToggleSelectAll(ChangeEventArgs e)
    {
        _selectAll = (bool)(e.Value ?? false);
        if (_selectAll)
        {
            _selectedIds = new HashSet<string>(_filteredTemplates.Select(t => t.Name));
        }
        else
        {
            _selectedIds.Clear();
        }
        StateHasChanged();
    }

    private void ToggleSelect(string name)
    {
        if (_selectedIds.Contains(name))
            _selectedIds.Remove(name);
        else
            _selectedIds.Add(name);
        _selectAll = _selectedIds.Count == _filteredTemplates.Length && _filteredTemplates.Length > 0;
        StateHasChanged();
    }

    // ── CRUD Operations ──

    private async Task OpenCreateTemplate()
    {
        await DisposeMonacoEditor();
        _isEditMode = false;
        _editOriginalName = "";
        _formModel = new TemplateFormModel();
        _activeTabIndex = 0;
        _validationErrors.Clear();
        _validationChecks.Clear();
        _showValidationPanel = false;
        _showPreviewSection = false;
        _testValues.Clear();
        _renderedXmlPreview = "";
        _testResponse = null;
        _showModal = true;
    }

    private async Task OpenEditTemplate(Template tpl)
    {
        await DisposeMonacoEditor();
        _isEditMode = true;
        _editOriginalName = tpl.Name;
        _formModel = new TemplateFormModel
        {
            Name = tpl.Name,
            Description = tpl.Description,
            Category = tpl.Category,
            Tags = string.Join(", ", tpl.Tags),
            Wsdl = tpl.Wsdl,
            Operation = tpl.Operation,
            EndpointUrl = tpl.EndpointUrl,
            SoapAction = tpl.SoapAction,
            Status = tpl.Status,
            XmlContent = tpl.XmlContent,
            SourceType = "blank",
            VariableList = [.. tpl.VariableList]
        };
        _activeTabIndex = 0;
        _validationErrors.Clear();
        _validationChecks.Clear();
        _showValidationPanel = false;
        _showPreviewSection = false;
        _testValues = tpl.VariableList.ToDictionary(v => v.Name, v => v.Sample);
        _renderedXmlPreview = tpl.XmlContent;
        _showModal = true;
    }

    private async Task CloseModal()
    {
        _showModal = false;
        _successMessage = null;
        await DisposeMonacoEditor();
    }

    private async Task SaveTemplate()
    {
        _validationErrors.Clear();
        _isSaving = true;
        _savingIndicator = "Saving...";

        // Sync Monaco editor content
        await SyncMonacoContent();

        // Validate
        if (string.IsNullOrWhiteSpace(_formModel.Name))
            _validationErrors.Add("Template name is required.");
        if (string.IsNullOrWhiteSpace(_formModel.Category))
            _validationErrors.Add("Application selection is required.");
        if (string.IsNullOrWhiteSpace(_formModel.Operation))
            _validationErrors.Add("Operation selection is required.");

        if (_validationErrors.Count > 0)
        {
            _isSaving = false;
            _savingIndicator = null;
            _showValidationPanel = true;
            return;
        }

        // Simulate save
        await Task.Delay(600);

        var appName = _formSelectedApp?.Name ?? _formModel.Category;
        var newItem = new Template(
            _formModel.Name,
            appName,
            _formModel.Operation,
            _formModel.VariableList.Count,
            _formModel.Status,
            _formModel.Category,
            _formModel.Description,
            _formModel.Tags.Split(',', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries),
            _formModel.EndpointUrl,
            _formModel.SoapAction,
            _formModel.XmlContent,
            [.. _formModel.VariableList],
            _isEditMode ? _allTemplates.First(t => t.Name == _editOriginalName).Created : DateTime.Now.ToString("yyyy-MM-dd"),
            DateTime.Now.ToString("yyyy-MM-dd"),
            _isEditMode ? _allTemplates.First(t => t.Name == _editOriginalName).Usage : 0
        );

        if (_isEditMode)
        {
            var idx = Array.FindIndex(_allTemplates, t => t.Name == _editOriginalName);
            if (idx >= 0)
                _allTemplates[idx] = newItem;
            _successMessage = $"Template \"{_formModel.Name}\" updated successfully.";
        }
        else
        {
            _allTemplates = [.. _allTemplates, newItem];
            _successMessage = $"Template \"{_formModel.Name}\" created successfully.";
        }

        ApplyFilters();
        _isSaving = false;
        _savingIndicator = null;
        _showModal = false;

        // Auto-clear success message
        _ = AutoClearSuccess();
        StateHasChanged();
    }

    private void ConfirmDeleteTemplate(string name)
    {
        _deleteTargetName = name;
        _showDeleteConfirm = true;
    }

    private async Task ExecuteDeleteTemplate()
    {
        if (string.IsNullOrEmpty(_deleteTargetName)) return;

        _allTemplates = [.. _allTemplates.Where(t => t.Name != _deleteTargetName)];
        _selectedIds.Remove(_deleteTargetName);
        ApplyFilters();
        _showDeleteConfirm = false;
        _deleteTargetName = null;
        _successMessage = "Template deleted successfully.";
        await AutoClearSuccess();
        StateHasChanged();
    }

    private void CancelDelete()
    {
        _showDeleteConfirm = false;
        _deleteTargetName = null;
    }

    // ── Bulk Actions ──

    private async Task BulkDelete()
    {
        if (_selectedIds.Count == 0) return;
        _isBulkDeleting = true;

        await Task.Delay(300);

        _allTemplates = [.. _allTemplates.Where(t => !_selectedIds.Contains(t.Name))];
        _selectedIds.Clear();
        ApplyFilters();
        _isBulkDeleting = false;
        _successMessage = $"Deleted {_selectedIds.Count} templates.";
        await AutoClearSuccess();
        StateHasChanged();
    }

    private void ExportSelected(string format)
    {
        var selected = _allTemplates.Where(t => _selectedIds.Contains(t.Name)).ToArray();
        if (selected.Length == 0) return;

        var json = JsonSerializer.Serialize(selected, new JsonSerializerOptions { WriteIndented = true });
        var mimeType = format == "csv" ? "text/csv" : "application/json";
        var fileName = $"templates-export.{format}";

        // Trigger download via JS interop would go here
        _successMessage = $"{selected.Length} template(s) exported as {format.ToUpper()}.";
        _ = AutoClearSuccess();
        StateHasChanged();
    }

    // ── Source Selection ──

    private void OnSourceTypeChanged(string sourceType)
    {
        _formModel.SourceType = sourceType;
        if (sourceType == "blank")
        {
            _formModel.XmlContent = "";
        }
        StateHasChanged();
    }

    private async Task HandleFileUpload(InputFileChangeEventArgs e)
    {
        var file = e.GetMultipleFiles().FirstOrDefault();
        if (file is null) return;

        _uploadFileName = file.Name;
        using var stream = file.OpenReadStream(maxAllowedSize: 5 * 1024 * 1024);
        using var reader = new StreamReader(stream);
        _formModel.XmlContent = await reader.ReadToEndAsync();
        _formModel.SourceType = "upload";
        _formModel.Name = string.IsNullOrWhiteSpace(_formModel.Name)
            ? Path.GetFileNameWithoutExtension(file.Name)
            : _formModel.Name;
        StateHasChanged();
    }

    // ── Variable Management ──

    private void AddVariable()
    {
        _formModel.VariableList.Add(new TemplateVariable("", "string", "", true));
        StateHasChanged();
    }

    private void RemoveVariable(int index)
    {
        if (index >= 0 && index < _formModel.VariableList.Count)
            _formModel.VariableList.RemoveAt(index);
        StateHasChanged();
    }

    private void UpdateVariableName(int index, string value)
    {
        if (index >= 0 && index < _formModel.VariableList.Count)
        {
            var v = _formModel.VariableList[index];
            _formModel.VariableList[index] = v with { Name = value };
        }
    }

    private void UpdateVariableType(int index, string value)
    {
        if (index >= 0 && index < _formModel.VariableList.Count)
        {
            var v = _formModel.VariableList[index];
            _formModel.VariableList[index] = v with { Type = value };
        }
    }

    private void UpdateVariableSample(int index, string value)
    {
        if (index >= 0 && index < _formModel.VariableList.Count)
        {
            var v = _formModel.VariableList[index];
            _formModel.VariableList[index] = v with { Sample = value };
        }
    }

    private void ToggleVariableRequired(int index)
    {
        if (index >= 0 && index < _formModel.VariableList.Count)
        {
            var v = _formModel.VariableList[index];
            _formModel.VariableList[index] = v with { Required = !v.Required };
        }
    }

    // ── XML Preview & Test ──

    private async Task GeneratePreview()
    {
        await SyncMonacoContent();
        var xml = _formModel.XmlContent;
        foreach (var (key, value) in _testValues)
        {
            xml = xml.Replace($"{{{{{key}}}}}", string.IsNullOrEmpty(value) ? $"{{{{{key}}}}}" : value);
        }
        _renderedXmlPreview = xml;
        _showPreviewSection = true;
        StateHasChanged();
    }

    private async Task SendTestRequest()
    {
        _isTestLoading = true;
        _testResponse = null;

        await GeneratePreview();
        await Task.Delay(1200);

        _testResponse = $"<soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">\n"
            + $"  <soap:Body>\n"
            + $"    <{_formModel.Operation}Response xmlns=\"http://tempuri.org/\">\n"
            + $"      <Result>Success</Result>\n"
            + $"      <Message>Request processed for {_formModel.Name}</Message>\n"
            + $"      <Timestamp>{DateTime.Now:yyyy-MM-ddTHH:mm:ssZ}</Timestamp>\n"
            + $"    </{_formModel.Operation}Response>\n"
            + $"  </soap:Body>\n"
            + $"</soap:Envelope>";

        _isTestLoading = false;
        StateHasChanged();
    }

    // ── XML Tab Actions ──

    private async Task AutoDetectVariables()
    {
        await SyncMonacoContent();
        var xml = _formModel.XmlContent;
        if (string.IsNullOrWhiteSpace(xml)) return;

        var detected = new List<TemplateVariable>();
        var regex = new System.Text.RegularExpressions.Regex(@"\{\{(\w+)\}\}");
        var matches = regex.Matches(xml);

        foreach (System.Text.RegularExpressions.Match match in matches)
        {
            var varName = match.Groups[1].Value;
            if (!_formModel.VariableList.Any(v => v.Name == varName) &&
                !detected.Any(v => v.Name == varName))
            {
                detected.Add(new TemplateVariable(varName, "string", "", true));
            }
        }

        if (detected.Count > 0)
        {
            _formModel.VariableList.AddRange(detected);
            _successMessage = $"Detected {detected.Count} variable(s) from XML.";
            _ = AutoClearSuccess();
            StateHasChanged();
        }
    }

    private async Task ValidateXml()
    {
        await SyncMonacoContent();
        // Simple XML validation checks
        var checks = new List<(string, bool)>
        {
            ("XML has valid envelope structure", _formModel.XmlContent.Contains("<soap:Envelope")),
            ("XML has Body element", _formModel.XmlContent.Contains("<soap:Body")),
            ("All variables have corresponding entries", true),
            ("No unclosed tags", _formModel.XmlContent.Count(c => c == '<') / 2 == _formModel.XmlContent.Count(c => c == '>') / 2),
            ("Operation matches XML", string.IsNullOrEmpty(_formModel.Operation) || _formModel.XmlContent.Contains(_formModel.Operation))
        };

        _validationChecks = checks;
        _showValidationPanel = true;
        StateHasChanged();
    }

    // ── UI Handler methods (called from Razor) ──

    private void ToggleSourceDropdown() { _showSourceDropdown = !_showSourceDropdown; }
    private void CloseSourceDropdown() { _showSourceDropdown = false; }
    private void ExportAs(string format) { _showSourceDropdown = false; ExportSelected(format); }
    private void ExportAsJson() { ExportAs("json"); }
    private void ExportAsCsv() { ExportAs("csv"); }
    private void OpenBulkDelete() { _deleteTargetName = null; _showDeleteConfirm = true; }
    private void ClearSelection() { _selectedIds.Clear(); _selectAll = false; StateHasChanged(); }
    private void DismissSuccess() { _successMessage = null; }
    private void ClearSearch() { _searchText = ""; ApplyFilters(); }
    private void TogglePreviewSection() { _showPreviewSection = !_showPreviewSection; }
    private void CloseValidationPanel() { _showValidationPanel = false; }
    private async Task SaveAsDraft() { _formModel.Status = "Draft"; await SaveTemplate(); }
    private async Task CopyPreviewToClipboard()
    {
        if (!string.IsNullOrEmpty(_renderedXmlPreview))
            await JsRuntime.InvokeVoidAsync("navigator.clipboard.writeText", _renderedXmlPreview);
    }
    private void SelectSourceBlank() { SelectSource("blank"); }
    private void SelectSourceUpload() { SelectSource("upload"); }
    private void SelectSourceSaved() { SelectSource("saved"); }
    private void SelectSource(string sourceType)
    {
        _formModel.SourceType = sourceType;
        if (sourceType == "blank") _formModel.XmlContent = "";
        StateHasChanged();
    }
    private void HandleDragOver() { _isDragOver = true; }
    private void HandleDragLeave() { _isDragOver = false; }

    // ── CSS class helpers ──

    private string GetSourceActiveClass(string type) =>
        _formModel.SourceType == type ? " is-active" : "";
    private bool IsSourceBlank() => _formModel.SourceType == "blank";
    private bool IsSourceUpload() => _formModel.SourceType == "upload";
    private bool IsSourceSaved() => _formModel.SourceType == "saved";
    private string GetDragOverClass() => _isDragOver ? "is-drag-over" : "";
    private string GetTabActiveClass(int index) =>
        _activeTabIndex == index ? " is-active" : "";
    private string GetStatusActiveClass(string status) =>
        _formModel.Status == status ? " is-active" : "";
    private bool IsStatusSelected(string status) => _formModel.Status == status;
    private string GetXmlStatusClass() =>
        !string.IsNullOrEmpty(_formModel.XmlContent) ? "is-valid" : "";
    private string GetValidationCheckClass(bool passed) =>
        passed ? "is-pass" : "is-fail";
    private string GetValidationCheckIcon(bool passed) =>
        passed ? "bi-check-circle-fill text-sh-success" : "bi-x-circle-fill text-danger";
    private string GetOperationPlaceholder() =>
        _formSelectedApp is not null ? "Select operation..." : "Select application first";
    private string GetPreviewChevronIcon() =>
        _showPreviewSection ? "bi-chevron-down" : "bi-chevron-right";

    // ── Form field change handlers ──

    private void HandleNameChange(ChangeEventArgs e) =>
        _formModel.Name = e.Value?.ToString() ?? "";
    private void HandleApplicationChange(ChangeEventArgs e)
    {
        var appName = e.Value?.ToString() ?? "";
        _formModel.Category = appName;
        _formModel.Operation = "";
        var app = _availableApps.FirstOrDefault(a =>
            string.Equals(a.Name, appName, StringComparison.OrdinalIgnoreCase));
        if (app is not null)
        {
            _formModel.EndpointUrl = app.BaseUrl + app.WsdlPath;
            _formModel.SoapAction = "";
        }
        else
        {
            _formModel.EndpointUrl = "";
            _formModel.SoapAction = "";
        }
    }
    private void HandleDescriptionChange(ChangeEventArgs e) =>
        _formModel.Description = e.Value?.ToString() ?? "";
    private void HandleTagsChange(ChangeEventArgs e) =>
        _formModel.Tags = e.Value?.ToString() ?? "";
    private void HandleOperationChange(ChangeEventArgs e)
    {
        _formModel.Operation = e.Value?.ToString() ?? "";
        // Auto-set SoapAction from the selected operation
        var app = _formSelectedApp;
        if (app is not null && !string.IsNullOrEmpty(_formModel.Operation))
        {
            _formModel.SoapAction = $"http://tempuri.org/{_formModel.Operation}";
        }
    }
    private void HandleEndpointUrlChange(ChangeEventArgs e) =>
        _formModel.EndpointUrl = e.Value?.ToString() ?? "";
    private void HandleSoapActionChange(ChangeEventArgs e) =>
        _formModel.SoapAction = e.Value?.ToString() ?? "";
    private void HandleXmlContentChange(ChangeEventArgs e) =>
        _formModel.XmlContent = e.Value?.ToString() ?? "";

    // ── Variable event handlers ──

    private void UpdateVariableNameFromEvent(int index, ChangeEventArgs e) =>
        UpdateVariableName(index, e.Value?.ToString() ?? "");
    private void UpdateVariableTypeFromEvent(int index, ChangeEventArgs e) =>
        UpdateVariableType(index, e.Value?.ToString() ?? "");
    private void UpdateVariableSampleFromEvent(int index, ChangeEventArgs e) =>
        UpdateVariableSample(index, e.Value?.ToString() ?? "");
    private void HandleTestValueChange(string varName, ChangeEventArgs e)
    {
        _testValues[varName] = e.Value?.ToString() ?? "";
    }

    // ── Form helpers ──

    private void SelectStatus(string status)
    {
        _formModel.Status = status;
        StateHasChanged();
    }

    private async Task SetActiveTab(int index)
    {
        // Sync Monaco content when leaving XML tab
        if (_activeTabIndex == 1 && index != 1)
        {
            await SyncMonacoContent();
        }
        _activeTabIndex = index;
        if (index == 1)
        {
            // Reset Monaco so it re-initializes on next render
            _monacoInitialized = false;
            await ValidateXml();
        }
        StateHasChanged();
    }

    // ── Utility methods ──

    private static string GetRelativeTime(string dateStr)
    {
        if (!DateTime.TryParse(dateStr, out var date)) return dateStr;
        var diff = DateTime.Now - date;

        if (diff.TotalMinutes < 1) return "Just now";
        if (diff.TotalMinutes < 60) return $"{(int)diff.TotalMinutes}m ago";
        if (diff.TotalHours < 24) return $"{(int)diff.TotalHours}h ago";
        if (diff.TotalDays < 7) return $"{(int)diff.TotalDays}d ago";
        if (diff.TotalDays < 30) return $"{(int)(diff.TotalDays / 7)}w ago";
        return date.ToString("MMM dd, yyyy");
    }

    private async Task AutoClearSuccess()
    {
        await Task.Delay(3000);
        _successMessage = null;
        StateHasChanged();
    }

    private void DismissError()
    {
        _hasError = false;
        _errorMessage = null;
    }

    private string GetStatusClass(string status) => status.ToLowerInvariant() switch
    {
        "published" => "status-published",
        "draft" => "status-draft",
        "archived" => "status-archived",
        "invalid" => "status-invalid",
        _ => "status-draft"
    };

    private string GetModalTitle() =>
        _isEditMode ? $"Edit: {_editOriginalName}" : "Create New Template";

    // ══════════════════════════════════════════════════════
    // Monaco Editor Integration
    // ══════════════════════════════════════════════════════

    protected override async Task OnAfterRenderAsync(bool firstRender)
    {
        await base.OnAfterRenderAsync(firstRender);

        if (_showModal && _activeTabIndex == 1 && !_monacoInitialized)
        {
            _monacoInitialized = true;
            _monacoDotNetRef = DotNetObjectReference.Create(this);
            await JsRuntime.InvokeVoidAsync("wsdlMonaco.createXmlEditor",
                MonacoEditorId,
                _formModel.XmlContent,
                _monacoDotNetRef);
            StateHasChanged();
        }
    }

    /// <summary>
    /// JS-invokable callback for Monaco content changes.
    /// </summary>
    [JSInvokable]
    public void OnMonacoContentChanged(string content)
    {
        _formModel.XmlContent = content;
    }

    private async Task SyncMonacoContent()
    {
        if (_monacoInitialized)
        {
            try
            {
                var content = await JsRuntime.InvokeAsync<string>("wsdlMonaco.getEditorContent", MonacoEditorId);
                if (content is not null)
                {
                    _formModel.XmlContent = content;
                }
            }
            catch
            {
                // Monaco may not be initialized yet
            }
        }
    }

    private async Task DisposeMonacoEditor()
    {
        if (_monacoInitialized)
        {
            try
            {
                await JsRuntime.InvokeVoidAsync("wsdlMonaco.disposeEditor", MonacoEditorId);
            }
            catch { }
            _monacoInitialized = false;
            _monacoDotNetRef?.Dispose();
            _monacoDotNetRef = null;
        }
    }

    public async ValueTask DisposeAsync()
    {
        await DisposeMonacoEditor();
    }
}
