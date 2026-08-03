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

    private class EditorStats
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