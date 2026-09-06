using System.Text.Json;
using System.Xml.Linq;
using LinqToDB;
using LinqToDB.Async;
using Microsoft.AspNetCore.Components;
using Microsoft.JSInterop;
using Microsoft.Extensions.Configuration;
using OrbitHub.Common;
using OrbitHub.Ui.Components;
using OrbitHub.Data.ServiceAppManagement;
using OrbitHub.FileManagement.Services;

namespace OrbitHub.FileManagement.Pages;

public partial class FileEditor : IDisposable
{
    [Inject]
    private NavigationManager Nav { get; set; } = default!;

    [Inject]
    private IJSRuntime JS { get; set; } = default!;

    [Inject]
    private IConfiguration Config { get; set; } = default!;

    [Inject]
    private OrbitHub.SoapApplications.Services.SoapAppStore AppStore { get; set; } = default!;

    [Inject]
    private FileStore FileStore { get; set; } = default!;

    private MonacoEditor? _monacoEditorRef;

    // ── State ──
    private bool _isLoading = true;
    private bool _isEmpty;
    private bool _hasError;
    private string? _errorMessage;
    private bool _isSaving;
    private bool _hasUnsavedChanges;
    private int _activeTab;

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
    private bool _minimapEnabled;

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
        _isEmpty = false;
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
                _isEmpty = true;
                _isLoading = false;
                return;
            }

            _fileName = fileParam;
            _editFileName = fileParam;

            // Resolve: try SOAP first, then REST
            if (!string.IsNullOrWhiteSpace(appParam))
            {
                var file = await FileStore.GetFileAsync(appParam, _fileName);
                if (file is not null)
                {
                    _fileId = file.Id.ToString();
                    _appName = file.ApplicationName;
                    _operation = file.Operation;
                    _verb = file.Verb;
                    _editDescription = file.Description;
                    _editStatus = file.IsActive ? "active" : "inactive";
                    _createdBy = file.CreatedBy;
                    _createdAt = file.CreatedAt.ToString("yyyy-MM-dd HH:mm:ss");
                    _lastUpdatedBy = file.LastUpdatedBy ?? "";
                    _lastUpdatedAt = file.LastUpdatedAt?.ToString("yyyy-MM-dd HH:mm:ss") ?? "";
                    _fileContent = file.Content;
                    _originalContent = _fileContent;
                    _isSoapFile = string.Equals(file.ServiceType, "SOAP", StringComparison.OrdinalIgnoreCase);
                    _isRestFile = string.Equals(file.ServiceType, "REST", StringComparison.OrdinalIgnoreCase);
                    _language = GetLanguageFromExtension(_fileName);
                    _versionNumber = await FileStore.GetVersionCountAsync(file.Id);
                    _hasPreviousVersion = _versionNumber > 0;
                }
                else
                {
                    _hasError = true;
                    _errorMessage = $"File '{_fileName}' not found for application '{appParam}'.";
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

    /// <summary>
    /// Called when the MonacoEditor component content changes.
    /// </summary>
    private async Task OnEditorContentChanged(string content)
    {
        _fileContent = content;
        _hasUnsavedChanges = content != _originalContent;
        StateHasChanged();
    }

    private async Task FormatDocumentAsync()
    {
        await Task.CompletedTask;
    }

    private async Task HandleUndoAsync()
    {
        await Task.CompletedTask;
    }

    private async Task HandleRedoAsync()
    {
        await Task.CompletedTask;
    }

    private async Task HandleFontFamilyChangedAsync(string fontFamily)
    {
        await Task.CompletedTask;
    }

    private async Task HandleFontSizeChangedAsync(int fontSize)
    {
        await Task.CompletedTask;
    }

    private async Task HandleThemeChangedAsync(string theme)
    {
        await Task.CompletedTask;
    }

    private async Task HandleWordWrapToggledAsync(bool enabled)
    {
        await Task.CompletedTask;
    }

    private async Task HandleLineNumbersToggledAsync(bool enabled)
    {
        await Task.CompletedTask;
    }

    private async Task HandleMinimapToggledAsync(bool enabled)
    {
        await Task.CompletedTask;
    }

    private async Task HandleSearchAsync(string query)
    {
        await Task.CompletedTask;
    }

    private async Task HandleGoToLineAsync(int lineNumber)
    {
        await Task.CompletedTask;
    }

    private async Task HandleActionMenuItemAsync(string itemId)
    {
        switch (itemId)
        {
            case "new":
                _fileContent = string.Empty;
                _hasUnsavedChanges = true;
                await _monacoEditorRef!.SetContentAsync(_fileContent);
                ShowValidation("New document started", false);
                break;
            case "open":
            case "recent":
                Nav.NavigateTo("/file/library");
                break;
            case "save":
                await SaveAsync();
                break;
            case "save-as":
                ShowValidation("Use File Name and Save to persist as a new name", false);
                break;
            case "export":
                await DownloadFileAsync();
                break;
            case "print":
                ShowValidation("Use browser print from the comparer page", false);
                break;
            case "close":
                GoBack();
                break;
            case "undo":
                await _monacoEditorRef!.ExecuteCommandAsync("undo");
                break;
            case "redo":
                await _monacoEditorRef!.ExecuteCommandAsync("redo");
                break;
            case "cut":
                await _monacoEditorRef!.ExecuteCommandAsync("editor.action.clipboardCutAction");
                break;
            case "copy":
                await _monacoEditorRef!.ExecuteCommandAsync("editor.action.clipboardCopyAction");
                break;
            case "paste":
                await _monacoEditorRef!.ExecuteCommandAsync("editor.action.clipboardPasteAction");
                break;
            case "select-all":
                await _monacoEditorRef!.ExecuteCommandAsync("editor.action.selectAll");
                break;
            case "duplicate":
                await _monacoEditorRef!.ExecuteCommandAsync("editor.action.copyLinesDownAction");
                break;
            case "delete-line":
                await _monacoEditorRef!.ExecuteCommandAsync("editor.action.deleteLines");
                break;
            case "move-line-up":
                await _monacoEditorRef!.ExecuteCommandAsync("editor.action.moveLinesUpAction");
                break;
            case "move-line-down":
                await _monacoEditorRef!.ExecuteCommandAsync("editor.action.moveLinesDownAction");
                break;
            case "find":
                await _monacoEditorRef!.OpenFindAsync();
                break;
            case "find-next":
                await _monacoEditorRef!.ExecuteCommandAsync("editor.action.nextMatchFindAction");
                break;
            case "find-prev":
                await _monacoEditorRef!.ExecuteCommandAsync("editor.action.previousMatchFindAction");
                break;
            case "replace":
            case "replace-all":
                await _monacoEditorRef!.OpenReplaceAsync();
                break;
            case "go-to-line":
                await _monacoEditorRef!.ExecuteCommandAsync("editor.action.gotoLine");
                break;
            case "go-to-symbol":
                await _monacoEditorRef!.ExecuteCommandAsync("editor.action.quickOutline");
                break;
            case "toggle-minimap":
                _minimapEnabled = !_minimapEnabled;
                await _monacoEditorRef!.SetEditorOptionAsync("minimap", _minimapEnabled);
                break;
            case "toggle-breadcrumbs":
                ShowValidation("Breadcrumbs toggle is not available in embedded editor", false);
                break;
            case "toggle-word-wrap":
                await _monacoEditorRef!.ExecuteCommandAsync("editor.action.toggleWordWrap");
                break;
            case "theme-dark":
                await _monacoEditorRef!.SetThemeAsync("vs-dark");
                break;
            case "theme-light":
                await _monacoEditorRef!.SetThemeAsync("vs-light");
                break;
            case "theme-high-contrast":
                await _monacoEditorRef!.SetThemeAsync("hc-black");
                break;
            case "xml-validate":
            case "validate":
                await ValidateDocumentAsync();
                break;
            case "xml-format":
                await _monacoEditorRef!.ExecuteCommandAsync("editor.action.formatDocument");
                break;
            case "xml-minify":
                await MinifyCurrentDocumentAsync();
                break;
            case "xml-collapse":
                await _monacoEditorRef!.ExecuteCommandAsync("editor.foldAll");
                break;
            case "xml-expand":
                await _monacoEditorRef!.ExecuteCommandAsync("editor.unfoldAll");
                break;
            case "xml-to-json":
                ShowValidation("XML to JSON conversion is not available in this page", false);
                break;
            case "json-to-xml":
                ShowValidation("JSON to XML conversion is not available in this page", false);
                break;
            case "xml-generate-xsd":
                ShowValidation("XSD generation is not available in this page", false);
                break;
            case "encoding-utf8":
            case "encoding-utf8-bom":
            case "encoding-utf16":
            case "encoding-ascii":
                ShowValidation($"{itemId.Replace("encoding-", string.Empty).ToUpperInvariant()} selected", false);
                break;
            case "line-lf":
            case "line-crlf":
            case "line-cr":
                ShowValidation($"{itemId.Replace("line-", string.Empty).ToUpperInvariant()} selected", false);
                break;
            case "compare":
                OpenComparer();
                break;
            case "statistics":
                ShowValidation($"Length: {_fileContent.Length} characters", false);
                break;
            case "shortcuts":
                ShowValidation("Use Monaco shortcuts: Ctrl/Cmd+S, Ctrl/Cmd+F, Ctrl/Cmd+H", false);
                break;
            case "settings":
                ShowValidation("Use toolbar selectors for font, size, theme and wrapping", false);
                break;
            case "reset":
                _fileContent = _originalContent;
                _hasUnsavedChanges = false;
                await _monacoEditorRef!.SetContentAsync(_fileContent);
                ShowValidation("Editor reset to last saved content", false);
                break;
            case "about":
                ShowValidation("Monaco editor embedded in Service Hub Enterprise", false);
                break;
            default:
                break;
        }
    }

    private async Task ValidateDocumentAsync()
    {
        // Content is already bound via two-way binding
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
        try
        {
            var module = await JS.InvokeAsync<IJSObjectReference>("import",
                "./_content/OrbitHub.SoapApplications/js/download.js");
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
            // Sync content from editor if available
            if (_monacoEditorRef is not null)
            {
                var editorContent = await _monacoEditorRef.GetContentAsync();
                if (editorContent is not null)
                {
                    _fileContent = editorContent;
                }
            }

            var currentUser = Config["Users:CurrentUser"] ?? "Current User";
            var now = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");

            var file = await FileStore.GetFileAsync(_appName, _fileName);
            if (file is null) return;

            await FileStore.SaveAsync(file, _editFileName.Trim(), _editDescription.Trim(),
                string.Equals(_editStatus, "active", StringComparison.OrdinalIgnoreCase), _fileContent, currentUser);
            _versionNumber++;

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

    private async Task SetActiveTab(int tab)
    {
        _activeTab = tab;
        StateHasChanged();

        // When switching to Content tab, resize the Monaco editor
        if (tab == 1 && _monacoEditorRef is not null)
        {
            await Task.Delay(50);
            await _monacoEditorRef.ResizeAsync();
        }
    }

    private void GoBack()
    {
        Nav.NavigateTo("/file/library");
    }

    private void DismissError()
    {
        _hasError = false;
        _errorMessage = null;
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

    private static string GetLanguageFromExtension(string fileName)
        => FileFormatHelper.GetLanguageFromExtension(fileName);

    private async Task MinifyCurrentDocumentAsync()
    {
        if (string.IsNullOrWhiteSpace(_fileContent))
        {
            ShowValidation("Content is empty", true);
            return;
        }

        try
        {
            if (_language == "json")
            {
                using var jsonDoc = JsonDocument.Parse(_fileContent);
                _fileContent = JsonSerializer.Serialize(jsonDoc.RootElement);
            }
            else
            {
                var xmlDoc = XDocument.Parse(_fileContent);
                _fileContent = xmlDoc.ToString(SaveOptions.DisableFormatting);
            }

            _hasUnsavedChanges = _fileContent != _originalContent;
            if (_monacoEditorRef is not null)
            {
                await _monacoEditorRef.SetContentAsync(_fileContent);
            }

            ShowValidation("Document minified", false);
        }
        catch (Exception ex)
        {
            ShowValidation($"Minify failed: {ex.Message}", true);
        }
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

        // Also show in the MonacoEditor component
        _monacoEditorRef?.ShowValidation(message, isError);
    }

    private void DismissValidation() => _validationMessage = null;

    public void Dispose()
    {
        _validationCts?.Cancel();
        _validationCts?.Dispose();
    }
}