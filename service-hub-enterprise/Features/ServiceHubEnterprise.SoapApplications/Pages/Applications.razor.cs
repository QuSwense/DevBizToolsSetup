using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Rendering;
using ServiceHubEnterprise.Grid.Components;
using ServiceHubEnterprise.SoapApplications.Core.Enums;
using ServiceHubEnterprise.SoapApplications.Models;
using ServiceHubEnterprise.SoapApplications.Services;

namespace ServiceHubEnterprise.SoapApplications.Pages;

public partial class Applications
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
    private SoapApp? _editingApp = null;
    private string _sortColumn = "";
    private bool _sortAscending = true;

    private static readonly Regex AppNameRegex = new(@"^[A-Za-z0-9äöüßÄÖÜ ]+$");
    private static readonly Regex WsdlPathRegex = new(@"^[A-Za-z0-9/?.&=_\-]+$");
    private static readonly Regex CSharpIdentifierRegex = new(@"^[A-Za-z_][A-Za-z0-9_]*$");

    private static readonly HashSet<string> CSharpKeywords = new(StringComparer.Ordinal)
    {
        "abstract","as","base","bool","break","byte","case","catch","char","checked","class",
        "const","continue","decimal","default","delegate","do","double","else","enum","event",
        "explicit","extern","false","finally","fixed","float","for","foreach","goto","if",
        "implicit","in","int","interface","internal","is","lock","long","namespace","new",
        "null","object","operator","out","override","params","private","protected","public",
        "readonly","ref","return","sbyte","sealed","short","sizeof","stackalloc","static",
        "string","struct","switch","this","throw","true","try","typeof","uint","ulong",
        "unchecked","unsafe","ushort","using","virtual","void","volatile","while"
    };

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
            new() { Title = "Operations", Sortable = true, Field = a => a.ApisCount }
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
                query = query.Where(a => a.ApisCount == ops);

            if (!string.IsNullOrWhiteSpace(_sortColumn))
            {
                query = _sortColumn switch
                {
                    "Name" => _sortAscending ? query.OrderBy(a => a.Name) : query.OrderByDescending(a => a.Name),
                    "BaseUrl" => _sortAscending ? query.OrderBy(a => a.BaseUrl) : query.OrderByDescending(a => a.BaseUrl),
                    "Status" => _sortAscending ? query.OrderBy(a => a.Status) : query.OrderByDescending(a => a.Status),
                    "UpdatedBy" => _sortAscending ? query.OrderBy(a => a.UpdatedBy) : query.OrderByDescending(a => a.UpdatedBy),
                    "CreatedDate" => _sortAscending ? query.OrderBy(a => a.CreatedAt) : query.OrderByDescending(a => a.CreatedAt),
                    "ApisCount" => _sortAscending ? query.OrderBy(a => a.ApisCount) : query.OrderByDescending(a => a.ApisCount),
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

    private void HandleAddApplication()
    {
        _validationErrors = [];

        if (string.IsNullOrWhiteSpace(_newAppName))
        {
            _validationErrors.Add("App name is required.");
        }
        else if (!AppNameRegex.IsMatch(_newAppName.Trim()))
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
             || !WsdlPathRegex.IsMatch(_newAppWsdlPath.Trim()))
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
                if (string.IsNullOrWhiteSpace(name)
                    || !CSharpIdentifierRegex.IsMatch(name)
                    || CSharpKeywords.Contains(name))
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
                _newApis.Count,
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
                _newApis.Count,
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
}
