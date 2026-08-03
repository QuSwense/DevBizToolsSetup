using Microsoft.AspNetCore.Components;
using Microsoft.EntityFrameworkCore;
using Microsoft.JSInterop;
using ServiceHubEnterprise.Data;
using ServiceHubEnterprise.FileManagement.Models;

namespace ServiceHubEnterprise.FileManagement.Pages;

public partial class FileViewer
{
    [Inject]
    private NavigationManager Nav { get; set; } = default!;

    [Inject]
    private IJSRuntime JS { get; set; } = default!;

    [Inject]
    private SoapDbContext SoapDb { get; set; } = default!;

    [Inject]
    private RestDbContext RestDb { get; set; } = default!;

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
                // Try SOAP
                var soapFile = await SoapDb.SoapRequestFiles
                    .AsNoTracking()
                    .FirstOrDefaultAsync(f => f.FileName == fileParam && f.AppName == appParam);

                if (soapFile is not null)
                {
                    _fileId = soapFile.Id;
                    _fileName = soapFile.FileName;
                    _appName = soapFile.AppName;
                    _operation = soapFile.ApiPath;
                    _verb = soapFile.Verb;
                    _description = soapFile.Description ?? "";
                    _status = soapFile.Status;
                    _createdBy = soapFile.CreatedBy;
                    _createdAt = soapFile.CreatedAt;
                    _updatedBy = soapFile.UpdatedBy ?? "";
                    _updatedAt = soapFile.UpdatedAt ?? "";
                    _fileContent = soapFile.Content ?? "";
                    _fileSize = FormatSize(_fileContent.Length);
                    _isSoapFile = true;
                    _language = GetLanguageFromExtension(_fileName);
                }
                else
                {
                    // Try REST
                    var restFile = await RestDb.RestRequestFiles
                        .AsNoTracking()
                        .FirstOrDefaultAsync(f => f.FileName == fileParam && f.AppName == appParam);

                    if (restFile is not null)
                    {
                        _fileId = restFile.Id;
                        _fileName = restFile.FileName;
                        _appName = restFile.AppName;
                        _operation = restFile.ApiPath;
                        _verb = restFile.Verb;
                        _description = restFile.Description ?? "";
                        _status = restFile.Status;
                        _createdBy = restFile.CreatedBy;
                        _createdAt = restFile.CreatedAt;
                        _updatedBy = restFile.UpdatedBy ?? "";
                        _updatedAt = restFile.UpdatedAt ?? "";
                        _fileContent = restFile.Content ?? "";
                        _fileSize = FormatSize(_fileContent.Length);
                        _isRestFile = true;
                        _language = GetLanguageFromExtension(_fileName);
                    }
                    else
                    {
                        _hasError = true;
                        _errorMessage = $"File '{fileParam}' not found for application '{appParam}'.";
                    }
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
                "./_content/ServiceHubEnterprise.SoapApplications/js/download.js");
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
    {
        var ext = Path.GetExtension(fileName)?.TrimStart('.').ToLowerInvariant();
        return ext switch
        {
            "json" => "json",
            "xml" => "xml",
            "wsdl" => "xml",
            "txt" => "plaintext",
            "csv" => "plaintext",
            _ => "plaintext"
        };
    }

    private static string FormatSize(int byteCount)
    {
        return byteCount switch
        {
            < 1024 => $"{byteCount} B",
            < 1024 * 1024 => $"{byteCount / 1024.0:F1} KB",
            _ => $"{byteCount / (1024.0 * 1024.0):F1} MB"
        };
    }
}