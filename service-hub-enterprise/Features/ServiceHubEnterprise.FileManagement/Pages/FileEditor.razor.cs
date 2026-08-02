using System.Text.Json;
using System.Xml.Linq;
using Microsoft.AspNetCore.Components;
using Microsoft.JSInterop;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using ServiceHubEnterprise.Data;
using ServiceHubEnterprise.Data.Entities;

namespace ServiceHubEnterprise.FileManagement.Pages;

public partial class FileEditor : IDisposable
{
    [Inject]
    private NavigationManager Nav { get; set; } = default!;

    [Inject]
    private IJSRuntime JS { get; set; } = default!;

    [Inject]
    private IConfiguration Config { get; set; } = default!;

    [Inject]
    private ServiceHubEnterprise.SoapApplications.Services.SoapAppStore AppStore { get; set; } = default!;

    [Inject]
    private SoapDbContext SoapDb { get; set; } = default!;

    [Inject]
    private RestDbContext RestDb { get; set; } = default!;

    [Inject]
    private FileManagementDbContext FmDb { get; set; } = default!;

    private const string MonacoContainerId = "file-editor-monaco";
    private DotNetObjectReference<FileEditor>? _dotNetRef;

    // ── State ──
    private bool _isLoading = true;
    private bool _hasError;
    private string? _errorMessage;
    private bool _monacoReady;
    private bool _isSaving;
    private bool _hasUnsavedChanges;

    // ── File identity ──
    private string _fileId = "";
    private string _fileName = "";
    private string _appName = "";
    private string _operation = "";
    private string _verb = "";
    private string _editFileName = "";
    private string _editDescription = "";
    private string _editStatus = "active";
    private string _createdBy = "";
    private string _createdAt = "";
    private string _lastUpdatedBy = "";
    private string _lastUpdatedAt = "";
    private string _fileContent = "";
    private string _originalContent = "";
    private string _language = "xml";
    private bool _isSoapFile;
    private bool _isRestFile;
    private int _versionNumber;
    private bool _hasPreviousVersion;

    private string _lastSavedLabel => !string.IsNullOrEmpty(_lastUpdatedAt)
        ? $"Last saved: {_lastUpdatedAt}"
        : "Not yet saved";

    // ── Validation ──
    private string? _validationMessage;
    private bool _validationIsError;
    private CancellationTokenSource? _validationCts;

    protected override async Task OnInitializedAsync()
    {
        await base.OnInitializedAsync();
        await InitializeAsync();
    }

    private async Task InitializeAsync()
    {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;

        try
        {
            // Parse query params
            var uri = Nav.ToAbsoluteUri(Nav.Uri);
            var query = System.Web.HttpUtility.ParseQueryString(uri.Query);

            var appParam = query["app"];
            var fileParam = query["file"];

            if (string.IsNullOrWhiteSpace(fileParam))
            {
                _hasError = true;
                _errorMessage = "No file specified. Use ?app=&file= or ?path= query parameters.";
                _isLoading = false;
                return;
            }

            _fileName = fileParam;
            _editFileName = fileParam;

            // Resolve: try SOAP first, then REST
            if (!string.IsNullOrWhiteSpace(appParam))
            {
                // Try SOAP
                var soapFile = await SoapDb.SoapRequestFiles
                    .AsNoTracking()
                    .FirstOrDefaultAsync(f => f.FileName == _fileName && f.AppName == appParam);

                if (soapFile is not null)
                {
                    _fileId = soapFile.Id;
                    _appName = soapFile.AppName;
                    _operation = soapFile.ApiPath;
                    _verb = soapFile.Verb;
                    _editDescription = soapFile.Description;
                    _editStatus = soapFile.Status;
                    _createdBy = soapFile.CreatedBy;
                    _createdAt = soapFile.CreatedAt;
                    _lastUpdatedBy = soapFile.UpdatedBy ?? "";
                    _lastUpdatedAt = soapFile.UpdatedAt ?? "";
                    _fileContent = soapFile.Content ?? "";
                    _originalContent = _fileContent;
                    _isSoapFile = true;
                    _language = GetLanguageFromExtension(_fileName);

                    // Check for previous versions
                    _versionNumber = await FmDb.FileVersions
                        .Where(v => v.SourceType == "soap" && v.SourceId == _fileId)
                        .MaxAsync(v => (int?)v.VersionNumber) ?? 0;
                    _hasPreviousVersion = _versionNumber > 0;
                }
                else
                {
                    // Try REST
                    var restFile = await RestDb.RestRequestFiles
                        .AsNoTracking()
                        .FirstOrDefaultAsync(f => f.FileName == _fileName && f.AppName == appParam);

                    if (restFile is not null)
                    {
                        _fileId = restFile.Id;
                        _appName = restFile.AppName;
                        _operation = restFile.ApiPath;
                        _verb = restFile.Verb;
                        _editDescription = restFile.Description;
                        _editStatus = restFile.Status;
                        _createdBy = restFile.CreatedBy;
                        _createdAt = restFile.CreatedAt;
                        _lastUpdatedBy = restFile.UpdatedBy ?? "";
                        _lastUpdatedAt = restFile.UpdatedAt ?? "";
                        _fileContent = restFile.Content ?? "";
                        _originalContent = _fileContent;
                        _isRestFile = true;
                        _language = GetLanguageFromExtension(_fileName);

                        _versionNumber = await FmDb.FileVersions
                            .Where(v => v.SourceType == "rest" && v.SourceId == _fileId)
                            .MaxAsync(v => (int?)v.VersionNumber) ?? 0;
                        _hasPreviousVersion = _versionNumber > 0;
                    }
                    else
                    {
                        _hasError = true;
                        _errorMessage = $"File '{_fileName}' not found for application '{appParam}'.";
                    }
                }
            }
            else
            {
                _hasError = true;
                _errorMessage = "Application parameter (?app=) is required for SOAP/REST files.";
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

    protected override async Task OnAfterRenderAsync(bool firstRender)
    {
        if (firstRender && !_hasError && !_isLoading)
        {
            await InitializeMonacoAsync();
        }
    }

    private async Task InitializeMonacoAsync()
    {
        try
        {
            _dotNetRef = DotNetObjectReference.Create(this);
            await JS.InvokeVoidAsync("wsdlMonaco.createCodeEditor",
                MonacoContainerId,
                _fileContent,
                _language,
                _dotNetRef);
            _monacoReady = true;
        }
        catch (Exception ex)
        {
            _hasError = true;
            _errorMessage = $"Failed to initialize editor: {ex.Message}";
        }
    }

    /// <summary>
    /// JS-invokable callback for Monaco content changes.
    /// </summary>
    [JSInvokable]
    public void OnMonacoContentChanged(string content)
    {
        _fileContent = content;
        _hasUnsavedChanges = content != _originalContent;
        StateHasChanged();
    }

    private async Task SyncMonacoContentAsync()
    {
        if (!_monacoReady) return;
        try
        {
            _fileContent = await JS.InvokeAsync<string>("wsdlMonaco.getEditorContent", MonacoContainerId);
        }
        catch
        {
            // Monaco may not be initialized yet
        }
    }

    private async Task FormatDocumentAsync()
    {
        if (!_monacoReady) return;
        try
        {
            var editor = await JS.InvokeAsync<object>("wsdlMonaco.getEditorContent", MonacoContainerId);
            // Monaco's format action via Ctrl+Shift+I or programmatic call
            await JS.InvokeVoidAsync("eval",
                $"document.querySelector('#{MonacoContainerId}').__editor?.getAction('editor.action.formatDocument')?.run()");
        }
        catch
        {
            // Format action may not be available
        }
    }

    private async Task ValidateDocumentAsync()
    {
        await SyncMonacoContentAsync();

        if (string.IsNullOrWhiteSpace(_fileContent))
        {
            ShowValidation("Content is empty", true);
            return;
        }

        try
        {
            if (_language == "xml")
            {
                XDocument.Parse(_fileContent);
                ShowValidation("XML is valid", false);
            }
            else if (_language == "json")
            {
                JsonDocument.Parse(_fileContent);
                ShowValidation("JSON is valid", false);
            }
            else
            {
                ShowValidation($"Content length: {_fileContent.Length} characters", false);
            }
        }
        catch (Exception ex)
        {
            ShowValidation($"Validation error: {ex.Message}", true);
        }
    }

    private async Task DownloadFileAsync()
    {
        await SyncMonacoContentAsync();
        try
        {
            var module = await JS.InvokeAsync<IJSObjectReference>("import",
                "./_content/ServiceHubEnterprise.SoapApplications/js/download.js");
            try
            {
                var mimeType = _language == "json" ? "application/json" : "text/xml";
                await module.InvokeVoidAsync("downloadTextFile", _fileContent, _editFileName, mimeType);
            }
            finally
            {
                await module.DisposeAsync();
            }
        }
        catch
        {
            ShowValidation("Download failed", true);
        }
    }

    private void OpenComparer()
    {
        if (_isSoapFile)
        {
            Nav.NavigateTo($"/file/comparer?leftApp={_appName}&leftFile={_fileName}&rightVersion=previous");
        }
        else if (_isRestFile)
        {
            Nav.NavigateTo($"/file/comparer?leftApp={_appName}&leftFile={_fileName}&rightVersion=previous");
        }
    }

    private async Task SaveAsync()
    {
        if (_isSaving) return;
        _isSaving = true;

        try
        {
            await SyncMonacoContentAsync();

            var currentUser = Config["Users:CurrentUser"] ?? "Current User";
            var now = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");

            if (_isSoapFile)
            {
                var entity = await SoapDb.SoapRequestFiles.FindAsync(_fileId);
                if (entity is null) return;

                entity.FileName = _editFileName.Trim();
                entity.Description = _editDescription.Trim();
                entity.Status = _editStatus;
                entity.UpdatedBy = currentUser;
                entity.UpdatedAt = now;
                entity.Content = _fileContent;

                // Snapshot version
                _versionNumber++;
                FmDb.FileVersions.Add(new FileVersionEntity
                {
                    Id = $"fv-{Guid.NewGuid():N}"[..12],
                    SourceType = "soap",
                    SourceId = _fileId,
                    FileName = _editFileName.Trim(),
                    Content = _originalContent,
                    SavedBy = currentUser,
                    SavedAt = now,
                    VersionNumber = _versionNumber
                });

                await SoapDb.SaveChangesAsync();
                await FmDb.SaveChangesAsync();
            }
            else if (_isRestFile)
            {
                var entity = await RestDb.RestRequestFiles.FindAsync(_fileId);
                if (entity is null) return;

                entity.FileName = _editFileName.Trim();
                entity.Description = _editDescription.Trim();
                entity.Status = _editStatus;
                entity.UpdatedBy = currentUser;
                entity.UpdatedAt = now;
                entity.Content = _fileContent;

                // Snapshot version
                _versionNumber++;
                FmDb.FileVersions.Add(new FileVersionEntity
                {
                    Id = $"fv-{Guid.NewGuid():N}"[..12],
                    SourceType = "rest",
                    SourceId = _fileId,
                    FileName = _editFileName.Trim(),
                    Content = _originalContent,
                    SavedBy = currentUser,
                    SavedAt = now,
                    VersionNumber = _versionNumber
                });

                await RestDb.SaveChangesAsync();
                await FmDb.SaveChangesAsync();
            }

            _originalContent = _fileContent;
            _hasUnsavedChanges = false;
            _lastUpdatedBy = currentUser;
            _lastUpdatedAt = now;
            _hasPreviousVersion = true;

            ShowValidation("File saved", false);
        }
        catch (Exception ex)
        {
            ShowValidation($"Save failed: {ex.Message}", true);
        }
        finally
        {
            _isSaving = false;
        }
    }

    private void GoBack()
    {
        Nav.NavigateTo("/soap/request-files");
    }

    private string GetFileExtension()
    {
        if (string.IsNullOrEmpty(_fileName)) return "xml";
        var ext = Path.GetExtension(_fileName)?.TrimStart('.').ToLowerInvariant();
        return ext switch
        {
            "json" => "json",
            "xml" => "xml",
            "wsdl" => "wsdl",
            "txt" => "txt",
            _ => ext ?? "xml"
        };
    }

    private string GetTypeBadgeClass()
    {
        return GetFileExtension() switch
        {
            "json" => "file-type-json",
            "xml" => "file-type-xml",
            "wsdl" => "file-type-wsdl",
            _ => "file-type-generic"
        };
    }

    private static string GetLanguageFromExtension(string fileName)
    {
        var ext = Path.GetExtension(fileName)?.TrimStart('.').ToLowerInvariant();
        return ext switch
        {
            "json" => "json",
            "xml" or "wsdl" or "soap" => "xml",
            "txt" or "csv" => "plaintext",
            _ => "xml"
        };
    }

    private void ShowValidation(string message, bool isError)
    {
        _validationMessage = message;
        _validationIsError = isError;
        _validationCts?.Cancel();
        _validationCts = new CancellationTokenSource();
        var token = _validationCts.Token;
        _ = Task.Run(async () =>
        {
            await Task.Delay(3000, token);
            if (!token.IsCancellationRequested)
            {
                _validationMessage = null;
                await InvokeAsync(StateHasChanged);
            }
        });
        StateHasChanged();
    }

    private void DismissValidation() => _validationMessage = null;

    public void Dispose()
    {
        _dotNetRef?.Dispose();
        _validationCts?.Cancel();
        _validationCts?.Dispose();
    }
}