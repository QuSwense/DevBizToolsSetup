using Microsoft.AspNetCore.Components;
using Microsoft.JSInterop;
using OrbitHub.FileManagement.Services;

namespace OrbitHub.FileManagement.Pages;

public partial class FileViewer
{
    [Inject]
    private NavigationManager Nav { get; set; } = default!;

    [Inject]
    private IJSRuntime JS { get; set; } = default!;

    [Inject]
    private FileStore FileStore { get; set; } = default!;

    private const string MonacoContainerId = "file-viewer-monaco";

    // ── State ──
    private bool _isLoading = true;
    private bool _isEmpty;
    private bool _hasError;
    private string? _errorMessage;
    private bool _monacoReady;
    private int _activeTab;

    // ── File data ──
    private string _fileId = "";
    private string _fileName = "";
    private string _appName = "";
    private string _operation = "";
    private string _verb = "";
    private string _fileContent = "";
    private string _language = "xml";
    private string _createdBy = "";
    private string _createdAt = "";
    private string _updatedBy = "";
    private string _updatedAt = "";
    private string _description = "";
    private string _status = "";
    private string _fileSize = "";
    private bool _isSoapFile;
    private bool _isRestFile;

    protected override async Task OnInitializedAsync()
    {
        await base.OnInitializedAsync();
        await LoadFileAsync();
    }

    private async Task LoadFileAsync()
    {
        _isLoading = true;
        _isEmpty = false;
        _hasError = false;
        _errorMessage = null;

        try
        {
            var uri = Nav.ToAbsoluteUri(Nav.Uri);
            var query = System.Web.HttpUtility.ParseQueryString(uri.Query);

            var appParam = query["app"];
            var fileParam = query["file"];

            if (string.IsNullOrWhiteSpace(fileParam))
            {
                _isEmpty = true;
                _isLoading = false;
                return;
            }

            if (!string.IsNullOrWhiteSpace(appParam))
            {
                var file = await FileStore.GetFileAsync(appParam, fileParam);
                if (file is not null)
                {
                    _fileId = file.Id.ToString();
                    _fileName = file.FileName;
                    _appName = file.ApplicationName;
                    _operation = file.Operation;
                    _verb = file.Verb;
                    _description = file.Description;
                    _status = file.IsActive ? "active" : "inactive";
                    _createdBy = file.CreatedBy;
                    _createdAt = file.CreatedAt.ToString("yyyy-MM-dd HH:mm:ss");
                    _updatedBy = file.LastUpdatedBy ?? "";
                    _updatedAt = file.LastUpdatedAt?.ToString("yyyy-MM-dd HH:mm:ss") ?? "";
                    _fileContent = file.Content;
                    _fileSize = FormatSize(_fileContent.Length);
                    _isSoapFile = string.Equals(file.ServiceType, "SOAP", StringComparison.OrdinalIgnoreCase);
                    _isRestFile = string.Equals(file.ServiceType, "REST", StringComparison.OrdinalIgnoreCase);
                    _language = GetLanguageFromExtension(_fileName);
                }
                else
                {
                    _hasError = true;
                    _errorMessage = $"File '{fileParam}' not found for application '{appParam}'.";
                }
            }
            else
            {
                _hasError = true;
                _errorMessage = "Application parameter (?app=) is required.";
            }
        }
        catch (Exception ex)
        {
            _hasError = true;
            _errorMessage = $"Failed to load file: {ex.Message}";
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

    private void SetActiveTab(int tab)
    {
        _activeTab = tab;
        StateHasChanged();
    }

    protected override async Task OnAfterRenderAsync(bool firstRender)
    {
        // Initialize read-only Monaco when the Content tab becomes visible
        if (_activeTab == 1 && !_monacoReady && !_hasError && !_isLoading && !_isEmpty)
        {
            await InitializeMonacoAsync();
        }
    }

    private async Task InitializeMonacoAsync()
    {
        try
        {
            await JS.InvokeVoidAsync("wsdlMonaco.createEditor",
                MonacoContainerId,
                _fileContent);
            _monacoReady = true;
        }
        catch (Exception ex)
        {
            _hasError = true;
            _errorMessage = $"Failed to initialize viewer: {ex.Message}";
        }
    }

    private async Task DownloadFileAsync()
    {
        try
        {
            var module = await JS.InvokeAsync<IJSObjectReference>("import",
                "./_content/OrbitHub.SoapApplications/js/download.js");
            try
            {
                var mimeType = _language == "json" ? "application/json" : "text/xml";
                await module.InvokeVoidAsync("downloadTextFile", _fileContent, _fileName, mimeType);
            }
            finally
            {
                await module.DisposeAsync();
            }
        }
        catch
        {
            // Download failed silently
        }
    }

    private void GoBack()
    {
        Nav.NavigateTo("/file/library");
    }

    private void OpenInEditor()
    {
        Nav.NavigateTo($"/file/editor?app={_appName}&file={_fileName}");
    }

    private static string GetLanguageFromExtension(string fileName)
        => FileFormatHelper.GetLanguageFromExtension(fileName, "plaintext");

    private static string FormatSize(int byteCount)
        => FileFormatHelper.FormatSize(byteCount);
}