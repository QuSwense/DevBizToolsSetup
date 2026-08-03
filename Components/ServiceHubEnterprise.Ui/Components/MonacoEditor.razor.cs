using Microsoft.AspNetCore.Components;
using Microsoft.JSInterop;
using ServiceHubEnterprise.Ui.Models;

namespace ServiceHubEnterprise.Ui.Components;

/// <summary>
/// Reusable Monaco Editor component with configurable toolbar, footer, and editor options.
/// Manages the full JS interop lifecycle — create, update, dispose, and content change callbacks.
/// </summary>
public partial class MonacoEditor : IAsyncDisposable
{
    private const string MonacoModule = "monacoEditor";
    private const string DefaultContainerId = "monaco-editor-default";

    [Inject]
    private IJSRuntime JS { get; set; } = default!;

    // ── Container identity ──
    private string _containerId = DefaultContainerId;
    private DotNetObjectReference<MonacoEditor>? _dotNetRef;
    private bool _editorCreated;
    private bool _editorInitializing;

    // ── Content ──
    private string _previousContent = "";
    private int _totalChars;
    private int _nonEmptyLines;
    private int _blankLines;
    private int _selectedChars;
    private long _fileSizeBytes;

    // ── Validation toast ──
    private string? _validationMessage;
    private bool _validationIsError;
    private CancellationTokenSource? _validationCts;

    /// <summary>
    /// Unique container element ID. Auto-generated if not set.
    /// </summary>
    [Parameter]
    public string? ContainerId { get; set; }

    /// <summary>
    /// Gets or sets the current editor content (two-way bindable).
    /// </summary>
    [Parameter]
    public string Content { get; set; } = "";

    [Parameter]
    public EventCallback<string> ContentChanged { get; set; }

    /// <summary>
    /// File name displayed in the toolbar.
    /// </summary>
    [Parameter]
    public string FileName { get; set; } = "";

    /// <summary>
    /// Optional file path shown in tooltip.
    /// </summary>
    [Parameter]
    public string? FilePath { get; set; }

    // ── Editor configuration ──
    [Parameter] public string Language { get; set; } = "xml";
    [Parameter] public string Theme { get; set; } = "vs-dark";
    [Parameter] public int FontSize { get; set; } = 11;
    [Parameter] public string FontFamily { get; set; } = "JetBrains Mono";
    [Parameter] public bool ReadOnly { get; set; }
    [Parameter] public bool WordWrapEnabled { get; set; } = true;
    [Parameter] public bool ShowMinimap { get; set; }
    [Parameter] public bool ShowLineNumbers { get; set; } = true;
    [Parameter] public bool ShowBreadcrumbs { get; set; }
    [Parameter] public bool ShowFolding { get; set; } = true;
    [Parameter] public bool ShowGlyphMargin { get; set; }
    [Parameter] public int TabSize { get; set; } = 2;
    [Parameter] public string? Placeholder { get; set; }

    // ── Encoding & file info ──
    [Parameter] public string FileEncoding { get; set; } = "UTF-8";
    [Parameter] public string LineEndingFormat { get; set; } = "LF";
    [Parameter] public bool IsOverwriteMode { get; set; }
    [Parameter] public bool IsAutoSaveEnabled { get; set; }
    [Parameter] public bool IsConnected { get; set; } = true;

    // ── State ──
    [Parameter] public bool IsLoading { get; set; }
    [Parameter] public bool HasError { get; set; }
    [Parameter] public string? ErrorMessage { get; set; }
    [Parameter] public bool HasUnsavedChanges { get; set; }
    [Parameter] public bool IsSaving { get; set; }
    [Parameter] public bool HasValidationErrors { get; set; }
    [Parameter] public int CursorLine { get; set; } = 1;
    [Parameter] public int CursorColumn { get; set; } = 1;

    // ── Toolbar section visibility ──
    [Parameter] public bool ShowToolbar { get; set; } = true;
    [Parameter] public bool ShowBackButton { get; set; } = true;
    [Parameter] public bool ShowFileName { get; set; } = true;
    [Parameter] public bool ShowFontSelector { get; set; } = true;
    [Parameter] public bool ShowWordWrapToggle { get; set; } = true;
    [Parameter] public bool ShowLineNumbersToggle { get; set; } = true;
    [Parameter] public bool ShowThemeSelector { get; set; } = true;
    [Parameter] public bool ShowSearchBox { get; set; } = true;
    [Parameter] public bool ShowCursorPosition { get; set; } = true;
    [Parameter] public bool ShowGoToLine { get; set; } = true;
    [Parameter] public bool ShowSaveButton { get; set; } = true;
    [Parameter] public bool ShowFormatButton { get; set; } = true;
    [Parameter] public bool ShowValidateButton { get; set; } = true;
    [Parameter] public bool ShowDownloadButton { get; set; } = true;
    [Parameter] public bool ShowCompareButton { get; set; } = true;
    [Parameter] public bool ShowUndoRedo { get; set; } = true;
    [Parameter] public bool ShowActionMenu { get; set; } = true;

    // ── Footer section visibility ──
    [Parameter] public bool ShowFooter { get; set; } = true;
    [Parameter] public bool ShowFooterLeftStats { get; set; } = true;
    [Parameter] public bool ShowFooterCenterStats { get; set; } = true;
    [Parameter] public bool ShowFooterRightStats { get; set; } = true;
    [Parameter] public bool ShowFooterWordWrapToggle { get; set; } = true;
    [Parameter] public bool ShowFooterMinimapToggle { get; set; } = true;

    // ── Custom content slots ──
    [Parameter] public RenderFragment? ToolbarContent { get; set; }
    [Parameter] public RenderFragment? FooterContent { get; set; }

    // ── Container height ──
    [Parameter] public string Height { get; set; } = "100%";

    // ── Auto-save ──
    [Parameter] public int AutoSaveIntervalMs { get; set; }
    private Timer? _autoSaveTimer;

    // ── Callbacks ──
    [Parameter] public EventCallback OnBackClick { get; set; }
    [Parameter] public EventCallback OnSaveClick { get; set; }
    [Parameter] public EventCallback OnFormatClick { get; set; }
    [Parameter] public EventCallback OnValidateClick { get; set; }
    [Parameter] public EventCallback OnDownloadClick { get; set; }
    [Parameter] public EventCallback OnCompareClick { get; set; }
    [Parameter] public EventCallback OnPrintClick { get; set; }
    [Parameter] public EventCallback OnUndo { get; set; }
    [Parameter] public EventCallback OnRedo { get; set; }
    [Parameter] public EventCallback OnRetry { get; set; }
    [Parameter] public EventCallback<string> OnFontFamilyChanged { get; set; }
    [Parameter] public EventCallback<int> OnFontSizeChanged { get; set; }
    [Parameter] public EventCallback<string> OnThemeChanged { get; set; }
    [Parameter] public EventCallback<bool> OnWordWrapToggled { get; set; }
    [Parameter] public EventCallback<bool> OnLineNumbersToggled { get; set; }
    [Parameter] public EventCallback<bool> OnMinimapToggled { get; set; }
    [Parameter] public EventCallback<string> OnSearch { get; set; }
    [Parameter] public EventCallback<int> OnGoToLine { get; set; }
    [Parameter] public EventCallback<string> OnActionMenuItem { get; set; }

    // ── Lifecycle ──

    protected override void OnInitialized()
    {
        _containerId = ContainerId ?? $"monaco-editor-{Guid.NewGuid():N}";
        _previousContent = Content;
        _fileSizeBytes = System.Text.Encoding.UTF8.GetByteCount(Content ?? "");
    }

    protected override async Task OnAfterRenderAsync(bool firstRender)
    {
        if (firstRender && !IsLoading && !HasError && !string.IsNullOrEmpty(Content))
        {
            _editorInitializing = true;
            await InitializeEditorAsync();
        }
    }

    private async Task InitializeEditorAsync()
    {
        try
        {
            _dotNetRef = DotNetObjectReference.Create(this);

            var opts = new
            {
                language = Language,
                theme = Theme,
                readOnly = ReadOnly,
                fontSize = FontSize,
                fontFamily = FontFamily,
                wordWrap = WordWrapEnabled,
                lineNumbers = ShowLineNumbers,
                minimap = ShowMinimap,
                folding = ShowFolding,
                glyphMargin = ShowGlyphMargin,
                tabSize = TabSize,
                paddingTop = 8,
                paddingBottom = 8,
                bracketPairColorization = true,
                autoClosingBrackets = "always",
                autoClosingQuotes = "always",
                formatOnPaste = true,
                renderLineHighlight = "line",
                snippetSuggestions = "inline",
                quickSuggestions = true,
                renderWhitespace = "selection",
                mouseWheelZoom = true
            };

            await JS.InvokeVoidAsync($"{MonacoModule}.createEditor", _containerId, Content, opts, _dotNetRef);
            _editorCreated = true;
            await RefreshStatsAsync();
            StateHasChanged();
        }
        catch (Exception ex)
        {
            HasError = true;
            ErrorMessage = $"Failed to initialize editor: {ex.Message}";
            StateHasChanged();
        }
        finally
        {
            _editorInitializing = false;
        }
    }

    /// <summary>
    /// JS-invokable callback for Monaco content changes.
    /// </summary>
    [JSInvokable]
    public async Task OnMonacoContentChanged(string content)
    {
        Content = content;
        _fileSizeBytes = System.Text.Encoding.UTF8.GetByteCount(content ?? "");
        HasUnsavedChanges = content != _previousContent;
        await RefreshStatsAsync();
        await ContentChanged.InvokeAsync(content);
        StateHasChanged();
    }

    /// <summary>
    /// JS-invokable callback for cursor/selection state changes.
    /// </summary>
    [JSInvokable]
    public Task OnMonacoEditorStateChanged(EditorStats? stats)
    {
        if (stats is null)
        {
            return Task.CompletedTask;
        }

        _totalChars = stats.TotalChars;
        _nonEmptyLines = stats.NonEmptyLines;
        _blankLines = stats.BlankLines;
        _selectedChars = stats.SelectedChars;
        CursorLine = stats.LineNumber;
        CursorColumn = stats.ColumnNumber;
        return InvokeAsync(StateHasChanged);
    }

    private async Task RefreshStatsAsync()
    {
        if (!_editorCreated) return;
        try
        {
            var stats = await JS.InvokeAsync<EditorStats?>($"{MonacoModule}.getEditorStats", _containerId);
            if (stats is not null)
            {
                _totalChars = stats.TotalChars;
                _nonEmptyLines = stats.NonEmptyLines;
                _blankLines = stats.BlankLines;
                _selectedChars = stats.SelectedChars;
                CursorLine = stats.LineNumber;
                CursorColumn = stats.ColumnNumber;
            }
        }
        catch
        {
            // Editor may not be ready yet
        }
    }

    // ── Public methods callable via @ref ──

    /// <summary>
    /// Forces the editor to re-measure and layout.
    /// </summary>
    public async Task ResizeAsync()
    {
        if (_editorCreated)
        {
            try { await JS.InvokeVoidAsync($"{MonacoModule}.resizeAll"); }
            catch { /* ignore */ }
        }
    }

    /// <summary>
    /// Gets the current editor content via JS interop.
    /// </summary>
    public async Task<string?> GetContentAsync()
    {
        if (!_editorCreated) return null;
        try
        {
            return await JS.InvokeAsync<string>($"{MonacoModule}.getEditorContent", _containerId);
        }
        catch { return null; }
    }

    /// <summary>
    /// Sets editor content programmatically.
    /// </summary>
    public async Task SetContentAsync(string content)
    {
        if (_editorCreated)
        {
            try
            {
                await JS.InvokeVoidAsync($"{MonacoModule}.setEditorContent", _containerId, content);
                Content = content;
                HasUnsavedChanges = content != _previousContent;
                _fileSizeBytes = System.Text.Encoding.UTF8.GetByteCount(content ?? "");
                await RefreshStatsAsync();
                StateHasChanged();
            }
            catch { /* ignore */ }
        }
    }

    /// <summary>
    /// Sets the editor language.
    /// </summary>
    public async Task SetLanguageAsync(string language)
    {
        if (_editorCreated)
        {
            try { await JS.InvokeVoidAsync($"{MonacoModule}.setEditorLanguage", _containerId, language); }
            catch { /* ignore */ }
        }
    }

    /// <summary>
    /// Sets the editor theme.
    /// </summary>
    public async Task SetThemeAsync(string theme)
    {
        if (_editorCreated)
        {
            try { await JS.InvokeVoidAsync($"{MonacoModule}.setEditorTheme", theme); }
            catch { /* ignore */ }
        }
    }

    /// <summary>
    /// Executes a Monaco editor command.
    /// </summary>
    public async Task ExecuteCommandAsync(string commandId)
    {
        if (_editorCreated)
        {
            try { await JS.InvokeVoidAsync($"{MonacoModule}.executeCommand", _containerId, commandId); }
            catch { /* ignore */ }
        }
    }

    /// <summary>
    /// Updates a single editor option value.
    /// </summary>
    public async Task SetEditorOptionAsync(string key, object value)
    {
        if (_editorCreated)
        {
            try { await JS.InvokeVoidAsync($"{MonacoModule}.setEditorOption", _containerId, key, value); }
            catch { /* ignore */ }
        }
    }

    /// <summary>
    /// Opens Monaco find widget.
    /// </summary>
    public async Task OpenFindAsync()
    {
        await ExecuteCommandAsync("actions.find");
    }

    /// <summary>
    /// Opens Monaco replace widget.
    /// </summary>
    public async Task OpenReplaceAsync()
    {
        await ExecuteCommandAsync("editor.action.startFindReplaceAction");
    }

    /// <summary>
    /// Searches for text and jumps to the next match.
    /// </summary>
    public async Task<bool> SearchAsync(string query)
    {
        if (!_editorCreated || string.IsNullOrWhiteSpace(query))
        {
            return false;
        }

        try
        {
            return await JS.InvokeAsync<bool>($"{MonacoModule}.searchInEditor", _containerId, query);
        }
        catch
        {
            return false;
        }
    }

    /// <summary>
    /// Jumps to a specific line number.
    /// </summary>
    public async Task GoToLineAsync(int lineNumber)
    {
        if (!_editorCreated || lineNumber <= 0)
        {
            return;
        }

        try
        {
            await JS.InvokeVoidAsync($"{MonacoModule}.goToLine", _containerId, lineNumber);
        }
        catch
        {
            // ignore
        }
    }

    private async Task HandleBackClickAsync()
    {
        await OnBackClick.InvokeAsync();
    }

    private async Task HandleSaveClickAsync()
    {
        await OnSaveClick.InvokeAsync();
    }

    private async Task HandleFormatClickAsync()
    {
        await ExecuteCommandAsync("editor.action.formatDocument");
        await OnFormatClick.InvokeAsync();
    }

    private async Task HandleValidateClickAsync()
    {
        await OnValidateClick.InvokeAsync();
    }

    private async Task HandleDownloadClickAsync()
    {
        await OnDownloadClick.InvokeAsync();
    }

    private async Task HandleCompareClickAsync()
    {
        await OnCompareClick.InvokeAsync();
    }

    private async Task HandleUndoAsync()
    {
        await ExecuteCommandAsync("undo");
        await RefreshStatsAsync();
        await OnUndo.InvokeAsync();
        StateHasChanged();
    }

    private async Task HandleRedoAsync()
    {
        await ExecuteCommandAsync("redo");
        await RefreshStatsAsync();
        await OnRedo.InvokeAsync();
        StateHasChanged();
    }

    private async Task HandleFontFamilyChangedAsync(string fontFamily)
    {
        FontFamily = fontFamily;
        await SetEditorOptionAsync("fontFamily", fontFamily);
        await OnFontFamilyChanged.InvokeAsync(fontFamily);
        StateHasChanged();
    }

    private async Task HandleFontSizeChangedAsync(int fontSize)
    {
        FontSize = fontSize;
        await SetEditorOptionAsync("fontSize", fontSize);
        await OnFontSizeChanged.InvokeAsync(fontSize);
        StateHasChanged();
    }

    private async Task HandleThemeChangedAsync(string theme)
    {
        Theme = theme;
        await SetThemeAsync(theme);
        await OnThemeChanged.InvokeAsync(theme);
        StateHasChanged();
    }

    private async Task HandleWordWrapToggledAsync(bool enabled)
    {
        WordWrapEnabled = enabled;
        await SetEditorOptionAsync("wordWrap", enabled);
        await OnWordWrapToggled.InvokeAsync(enabled);
        StateHasChanged();
    }

    private async Task HandleLineNumbersToggledAsync(bool enabled)
    {
        ShowLineNumbers = enabled;
        await SetEditorOptionAsync("lineNumbers", enabled);
        await OnLineNumbersToggled.InvokeAsync(enabled);
        StateHasChanged();
    }

    private async Task HandleMinimapToggledAsync(bool enabled)
    {
        ShowMinimap = enabled;
        await SetEditorOptionAsync("minimap", enabled);
        await OnMinimapToggled.InvokeAsync(enabled);
        StateHasChanged();
    }

    private async Task HandleSearchAsync(string query)
    {
        if (!string.IsNullOrWhiteSpace(query))
        {
            var found = await SearchAsync(query);
            if (!found)
            {
                ShowValidation($"No matches for '{query}'", true);
            }
        }

        await OnSearch.InvokeAsync(query);
    }

    private async Task HandleGoToLineAsync(int lineNumber)
    {
        await GoToLineAsync(lineNumber);
        await RefreshStatsAsync();
        await OnGoToLine.InvokeAsync(lineNumber);
        StateHasChanged();
    }

    private async Task HandleActionMenuItemAsync(string itemId)
    {
        if (OnActionMenuItem.HasDelegate)
        {
            await OnActionMenuItem.InvokeAsync(itemId);
            return;
        }

        switch (itemId)
        {
            case "save":
                await HandleSaveClickAsync();
                break;
            case "print":
                await OnPrintClick.InvokeAsync();
                break;
            case "close":
                await HandleBackClickAsync();
                break;
            case "undo":
                await HandleUndoAsync();
                break;
            case "redo":
                await HandleRedoAsync();
                break;
            case "cut":
                await ExecuteCommandAsync("editor.action.clipboardCutAction");
                break;
            case "copy":
                await ExecuteCommandAsync("editor.action.clipboardCopyAction");
                break;
            case "paste":
                await ExecuteCommandAsync("editor.action.clipboardPasteAction");
                break;
            case "select-all":
                await ExecuteCommandAsync("editor.action.selectAll");
                break;
            case "duplicate":
                await ExecuteCommandAsync("editor.action.copyLinesDownAction");
                break;
            case "delete-line":
                await ExecuteCommandAsync("editor.action.deleteLines");
                break;
            case "move-line-up":
                await ExecuteCommandAsync("editor.action.moveLinesUpAction");
                break;
            case "move-line-down":
                await ExecuteCommandAsync("editor.action.moveLinesDownAction");
                break;
            case "find":
                await OpenFindAsync();
                break;
            case "find-next":
                await ExecuteCommandAsync("editor.action.nextMatchFindAction");
                break;
            case "find-prev":
                await ExecuteCommandAsync("editor.action.previousMatchFindAction");
                break;
            case "replace":
            case "replace-all":
                await OpenReplaceAsync();
                break;
            case "go-to-line":
                await ExecuteCommandAsync("editor.action.gotoLine");
                break;
            case "go-to-symbol":
                await ExecuteCommandAsync("editor.action.quickOutline");
                break;
            case "toggle-minimap":
                await HandleMinimapToggledAsync(!ShowMinimap);
                break;
            case "toggle-word-wrap":
                await HandleWordWrapToggledAsync(!WordWrapEnabled);
                break;
            case "theme-dark":
                await HandleThemeChangedAsync("vs-dark");
                break;
            case "theme-light":
                await HandleThemeChangedAsync("vs-light");
                break;
            case "theme-high-contrast":
                await HandleThemeChangedAsync("hc-black");
                break;
            case "xml-validate":
            case "validate":
                await HandleValidateClickAsync();
                break;
            case "xml-format":
                await HandleFormatClickAsync();
                break;
            case "xml-collapse":
                await ExecuteCommandAsync("editor.foldAll");
                break;
            case "xml-expand":
                await ExecuteCommandAsync("editor.unfoldAll");
                break;
            case "compare":
                await HandleCompareClickAsync();
                break;
            case "reset":
                await SetContentAsync(Content);
                await RefreshStatsAsync();
                break;
            default:
                break;
        }
    }

    // ── Toast helpers ──

    /// <summary>
    /// Shows a validation toast message.
    /// </summary>
    public void ShowValidation(string message, bool isError)
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

    private string GetLanguageBadge()
    {
        var ext = Path.GetExtension(FileName)?.TrimStart('.').ToLowerInvariant();
        return ext switch
        {
            "json" => "json",
            "xml" => "xml",
            "wsdl" => "wsdl",
            "txt" => "txt",
            _ => ext ?? Language
        };
    }

    // ── Dispose ──

    public async ValueTask DisposeAsync()
    {
        _autoSaveTimer?.Dispose();
        _validationCts?.Cancel();
        _validationCts?.Dispose();

        if (_editorCreated)
        {
            try
            {
                await JS.InvokeVoidAsync($"{MonacoModule}.disposeEditor", _containerId);
            }
            catch { /* ignore */ }
        }

        _dotNetRef?.Dispose();
    }

    // ── Internal DTO for editor stats ──

    public class EditorStats
    {
        public int TotalLines { get; set; }
        public int NonEmptyLines { get; set; }
        public int BlankLines { get; set; }
        public int TotalChars { get; set; }
        public int CharsNoSpaces { get; set; }
        public int SelectedChars { get; set; }
        public int LineNumber { get; set; }
        public int ColumnNumber { get; set; }
        public int CharacterPosition { get; set; }
    }
}