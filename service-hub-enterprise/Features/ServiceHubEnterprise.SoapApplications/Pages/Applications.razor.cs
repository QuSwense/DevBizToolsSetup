using ServiceHubEnterprise.Grid.Components;
using ServiceHubEnterprise.SoapApplications.Services;

namespace ServiceHubEnterprise.SoapApplications.Pages;

public partial class Applications
{
    private List<GridColumn<SoapApp>> _columns = [];

    private string _searchText = "";
    private string _filterName = "";
    private string _filterUrl = "";
    private string _filterStatus = "";
    private string _filterUpdatedBy = "";
    private string _filterCreatedDate = "";
    private string _filterOperations = "";
    private int _currentPage = 1;
    private bool _showFilterModal = false;
    private bool _showAddModal = false;
    private List<string> _validationErrors = [];
    private string _newAppName = "";
    private string _newAppUrl = "";
    private string _newAppWsdlPath = "";
    private string _newAppDescription = "";
    private string _newAppStatus = "enabled";
    private string _newAuthType = "basic";
    private string _newAuthUsername = "";
    private string _newAuthPassword = "";
    private string _newAuthExtra = "";
    private List<SoapApiEntry> _newApis = [];
    private bool _showDropdown = false;
    private HashSet<string> _expandedActionRows = [];
    private SoapApp? _editingApp = null;
    private string _sortColumn = "";
    private bool _sortAscending = true;

    protected override void OnInitialized()
    {
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
                    var badgeClass = context.Status == "enabled" ? "status-enabled" : "status-disabled";
                    var label = context.Status == "enabled" ? "Enabled" : "Disabled";
                    builder.OpenElement(0, "span");
                    builder.AddAttribute(1, "class", $"status-badge {badgeClass}");
                    builder.AddContent(2, label);
                    builder.CloseElement();
                }
            },
            new() { Title = "Last Updated By", Sortable = true, Field = a => a.UpdatedBy },
            new() { Title = "Created Date", Sortable = true, Field = a => a.CreatedDate },
            new() { Title = "Operations", Sortable = true, Field = a => a.ApisCount }
        ];
    }

    private SoapApp[] FilteredApps
    {
        get
        {
            var query = _appStore.Apps.AsEnumerable();

            if (!string.IsNullOrWhiteSpace(_searchText))
            {
                var q = _searchText.ToLower();
                query = query.Where(a =>
                    a.Name.ToLower().Contains(q) ||
                    a.BaseUrl.ToLower().Contains(q) ||
                    a.UpdatedBy.ToLower().Contains(q) ||
                    a.Status.ToLower().Contains(q));
            }

            if (!string.IsNullOrWhiteSpace(_filterName))
                query = query.Where(a => a.Name.ToLower().Contains(_filterName.ToLower()));
            if (!string.IsNullOrWhiteSpace(_filterUrl))
                query = query.Where(a => a.BaseUrl.ToLower().Contains(_filterUrl.ToLower()));
            if (!string.IsNullOrWhiteSpace(_filterStatus))
                query = query.Where(a => a.Status == _filterStatus);
            if (!string.IsNullOrWhiteSpace(_filterUpdatedBy))
                query = query.Where(a => a.UpdatedBy.ToLower().Contains(_filterUpdatedBy.ToLower()));
            if (!string.IsNullOrWhiteSpace(_filterCreatedDate))
                query = query.Where(a => a.CreatedDate.ToLower().Contains(_filterCreatedDate.ToLower()));
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
                    "CreatedDate" => _sortAscending ? query.OrderBy(a => a.CreatedDate) : query.OrderByDescending(a => a.CreatedDate),
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
        _newAuthType = app.AuthType;
        _newAuthUsername = app.AuthUsername;
        _newAuthPassword = app.AuthPassword;
        _newAuthExtra = app.AuthExtra;
        _newApis = [..app.Apis];
        _expandedActionRows.Remove(app.Id);
        _validationErrors = [];
        _showAddModal = true;
    }

    private void HandleAddApplication()
    {
        _validationErrors = [];

        if (string.IsNullOrWhiteSpace(_newAppName))
            _validationErrors.Add("App name is required.");
        if (string.IsNullOrWhiteSpace(_newAppUrl))
            _validationErrors.Add("Base URL is required.");
        if (_newApis.Count == 0)
            _validationErrors.Add("At least one SOAP API must be added.");

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
                _editingApp.UpdatedBy,
                _editingApp.CreatedDate,
                _newApis.Count,
                _newAuthType,
                _newAuthUsername.Trim(),
                _newAuthPassword.Trim(),
                _newAuthExtra.Trim(),
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
                "Anonymous",
                DateTime.Now.ToString("yyyy-MM-dd"),
                _newApis.Count,
                _newAuthType,
                _newAuthUsername.Trim(),
                _newAuthPassword.Trim(),
                _newAuthExtra.Trim(),
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
        _newAppStatus = "enabled";
        _newAuthType = "basic";
        _newAuthUsername = "";
        _newAuthPassword = "";
        _newAuthExtra = "";
        _newApis = [];
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
        _filterCreatedDate = "";
        _filterOperations = "";
        _currentPage = 1;
    }
}
