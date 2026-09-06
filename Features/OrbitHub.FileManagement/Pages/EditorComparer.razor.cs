using Microsoft.AspNetCore.Components;
using LinqToDB;
using LinqToDB.Async;
using Microsoft.JSInterop;
using OrbitHub.Common;
using OrbitHub.Ui.Components;
using OrbitHub.Ui.Models;
using OrbitHub.Data.ServiceAppManagement;
using OrbitHub.FileManagement.Services;

namespace OrbitHub.FileManagement.Pages;

public partial class EditorComparer
{
    [Inject]
    private NavigationManager Nav { get; set; } = default!;

    [Inject]
    private FileStore FileStore { get; set; } = default!;

    private MonacoDiffEditor? _diffEditorRef;

    // ── State ──
    private bool _isLoading = true;
    private bool _isEmpty;
    private bool _hasError;
    private string? _errorMessage;

    // ── Comparison state ──
    private string _leftFileName = "";
    private string _rightFileName = "";
    private string _leftContent = "";
    private string _rightContent = "";
    private string _leftLanguage = "xml";
    private string _rightLanguage = "xml";
    private string? _leftAuthor;
    private string? _rightAuthor;
    private string? _leftTimestamp;
    private string? _rightTimestamp;

    protected override async Task OnInitializedAsync()
    {
        await base.OnInitializedAsync();
        await LoadComparerAsync();
    }

    private async Task LoadComparerAsync()
    {
        _isLoading = true;
        _isEmpty = false;
        _hasError = false;
        _errorMessage = null;

        try
        {
            var uri = Nav.ToAbsoluteUri(Nav.Uri);
            var query = System.Web.HttpUtility.ParseQueryString(uri.Query);

            var leftApp = query["leftApp"];
            var leftFile = query["leftFile"];
            var rightApp = query["rightApp"];
            var rightFile = query["rightFile"];
            var rightVersion = query["rightVersion"];

            if (string.IsNullOrWhiteSpace(leftFile) && string.IsNullOrWhiteSpace(rightFile))
            {
                _isEmpty = true;
                _isLoading = false;
                return;
            }

            // Load left file content
            _leftFileName = leftFile ?? "(unknown)";
            _leftLanguage = GetLanguageFromExtension(_leftFileName);

            if (!string.IsNullOrWhiteSpace(leftApp) && !string.IsNullOrWhiteSpace(leftFile))
            {
                var file = await FileStore.GetFileAsync(leftApp, leftFile);
                if (file is not null)
                {
                    _leftContent = file.Content;
                    _leftAuthor = file.LastUpdatedBy ?? file.CreatedBy;
                    _leftTimestamp = (file.LastUpdatedAt ?? file.CreatedAt).ToString("yyyy-MM-dd HH:mm:ss");
                }
            }

            // Load right file content
            if (rightVersion == "previous" && leftApp is not null && leftFile is not null)
            {
                var source = await FileStore.GetFileAsync(leftApp, leftFile);
                if (source is not null)
                {
                    var previousVersion = await FileStore.GetPreviousVersionAsync(source.Id);

                    if (previousVersion is not null)
                    {
                        _rightContent = previousVersion.Content;
                        _rightFileName = previousVersion.FileName;
                        _rightAuthor = previousVersion.LastUpdatedBy ?? previousVersion.CreatedBy;
                        _rightTimestamp = (previousVersion.LastUpdatedAt ?? previousVersion.CreatedAt)
                            .ToString("yyyy-MM-dd HH:mm:ss");
                    }
                    else
                    {
                        _rightContent = _leftContent;
                        _rightFileName = $"{leftFile} (no previous version)";
                    }
                }
            }
            else if (!string.IsNullOrWhiteSpace(rightFile))
            {
                _rightFileName = rightFile;
                _rightLanguage = GetLanguageFromExtension(rightFile);

                if (!string.IsNullOrWhiteSpace(rightApp))
                {
                    var file = await FileStore.GetFileAsync(rightApp, rightFile);
                    if (file is not null)
                    {
                        _rightContent = file.Content;
                        _rightAuthor = file.LastUpdatedBy ?? file.CreatedBy;
                        _rightTimestamp = (file.LastUpdatedAt ?? file.CreatedAt).ToString("yyyy-MM-dd HH:mm:ss");
                    }
                }
            }
            else
            {
                _rightContent = _leftContent;
                _rightFileName = $"{leftFile} (same)";
            }

            _rightLanguage = GetLanguageFromExtension(_rightFileName);
        }
        catch (Exception ex)
        {
            _hasError = true;
            _errorMessage = $"Failed to load comparison: {ex.Message}";
        }
        finally
        {
            _isLoading = false;
        }
    }

    private async Task OnViewModeChanged(EDiffViewMode mode)
    {
        if (_diffEditorRef is not null)
        {
            await _diffEditorRef.ToggleViewModeAsync(mode);
        }
    }

    private async Task OnPreviousDiff()
    {
        if (_diffEditorRef is not null)
        {
            await _diffEditorRef.NavigatePreviousAsync();
        }
    }

    private async Task OnNextDiff()
    {
        if (_diffEditorRef is not null)
        {
            await _diffEditorRef.NavigateNextAsync();
        }
    }

    private async Task OnSwap()
    {
        if (_diffEditorRef is not null)
        {
            await _diffEditorRef.SwapAsync();
        }
    }

    private async Task OnRefresh()
    {
        await LoadComparerAsync();
    }

    private async Task OnExportReport()
    {
        // Placeholder: will implement export as unified diff / HTML report
        var report = $"Comparison Report\n" +
                     $"Left: {_leftFileName}\n" +
                     $"Right: {_rightFileName}\n" +
                     $"---\n" +
                     $"--- Left ---\n{_leftContent}\n\n" +
                     $"--- Right ---\n{_rightContent}";

        var module = await JS.InvokeAsync<IJSObjectReference>("import",
            "./_content/OrbitHub.SoapApplications/js/download.js");
        try
        {
            await module.InvokeVoidAsync("downloadTextFile", report, $"diff-{_leftFileName}-vs-{_rightFileName}.txt", "text/plain");
        }
        finally
        {
            await module.DisposeAsync();
        }
    }

    [Inject]
    private IJSRuntime JS { get; set; } = default!;

    private void DismissError()
    {
        _hasError = false;
        _errorMessage = null;
    }

    private void GoBack()
    {
        Nav.NavigateTo("/file/library");
    }

    private static string GetLanguageFromExtension(string fileName)
        => FileFormatHelper.GetLanguageFromExtension(fileName);
}