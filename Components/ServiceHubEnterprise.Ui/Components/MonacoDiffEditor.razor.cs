using Microsoft.AspNetCore.Components;
using Microsoft.JSInterop;
using ServiceHubEnterprise.Ui.Models;

namespace ServiceHubEnterprise.Ui.Components;

/// <summary>
/// Reusable Monaco diff editor component for side-by-side/inline comparison of two file versions.
/// Manages the full JS interop lifecycle for the diff editor.
/// </summary>
public partial class MonacoDiffEditor : IAsyncDisposable
{
    private const string MonacoModule = "monacoEditor";
    private const string DefaultContainerId = "monaco-diff-default";

    [Inject]
    private IJSRuntime JS { get; set; } = default!;

    private string _containerId = DefaultContainerId;
    private bool _editorCreated;

    /// <summary>
    /// Unique container element ID. Auto-generated if not set.
    /// </summary>
    [Parameter] public string? ContainerId { get; set; }

    // ── Content ──
    [Parameter] public string OriginalContent { get; set; } = "";
    [Parameter] public string ModifiedContent { get; set; } = "";

    // ── Labels ──
    [Parameter] public string OriginalLabel { get; set; } = "Original";
    [Parameter] public string ModifiedLabel { get; set; } = "Modified";
    [Parameter] public string? OriginalAuthor { get; set; }
    [Parameter] public string? ModifiedAuthor { get; set; }
    [Parameter] public string? OriginalTimestamp { get; set; }
    [Parameter] public string? ModifiedTimestamp { get; set; }

    // ── Editor config ──
    [Parameter] public string Language { get; set; } = "xml";
    [Parameter] public string Theme { get; set; } = "vs-dark";
    [Parameter] public int FontSize { get; set; } = 11;
    [Parameter] public string FontFamily { get; set; } = "JetBrains Mono";
    [Parameter] public bool ReadOnly { get; set; } = true;
    [Parameter] public bool WordWrap { get; set; } = true;
    [Parameter] public bool ShowMinimap { get; set; }
    [Parameter] public bool ShowLineNumbers { get; set; } = true;
    [Parameter] public bool IgnoreTrimWhitespace { get; set; }
    [Parameter] public bool IgnoreCase { get; set; }

    // ── View mode ──
    [Parameter] public DiffViewMode ViewMode { get; set; } = DiffViewMode.SideBySide;

    // ── Section visibility ──
    [Parameter] public bool ShowHeader { get; set; } = true;
    [Parameter] public bool ShowControls { get; set; } = true;
    [Parameter] public bool ShowFooter { get; set; } = true;
    [Parameter] public bool ShowUnchangedLines { get; set; } = true;
    [Parameter] public bool ShowUnchangedLinesToggle { get; set; } = true;
    [Parameter] public bool ShowWhitespaceToggles { get; set; } = true;
    [Parameter] public bool ShowCaseToggle { get; set; } = true;
    [Parameter] public bool ShowNavigation { get; set; } = true;
    [Parameter] public bool ShowDiffCounter { get; set; } = true;
    [Parameter] public bool ShowScrollSync { get; set; } = true;
    [Parameter] public bool ShowViewModeToggle { get; set; } = true;
    [Parameter] public bool ShowSwapButton { get; set; } = true;
    [Parameter] public bool ShowRefreshButton { get; set; } = true;
    [Parameter] public bool ShowExportButton { get; set; } = true;
    [Parameter] public bool ShowDiffStats { get; set; } = true;
    [Parameter] public bool ShowStatus { get; set; } = true;

    // ── Custom content slots ──
    [Parameter] public RenderFragment? ControlsContent { get; set; }
    [Parameter] public RenderFragment? FooterContent { get; set; }

    // ── State ──
    [Parameter] public bool IsLoading { get; set; }
    [Parameter] public bool HasError { get; set; }
    [Parameter] public string? ErrorMessage { get; set; }
    [Parameter] public bool IsProcessing { get; set; }

    // ── Diff stats ──
    [Parameter] public int TotalDifferences { get; set; }
    [Parameter] public int Additions { get; set; }
    [Parameter] public int Deletions { get; set; }
    [Parameter] public int Modifications { get; set; }
    [Parameter] public double PercentageChanged { get; set; }
    [Parameter] public double SimilarityPercentage { get; set; }
    [Parameter] public int CurrentDifference { get; set; }
    [Parameter] public bool ScrollSync { get; set; } = true;

    // ── Callbacks ──
    [Parameter] public EventCallback OnRetry { get; set; }
    [Parameter] public EventCallback<DiffViewMode> OnViewModeChanged { get; set; }
    [Parameter] public EventCallback OnPreviousDiff { get; set; }
    [Parameter] public EventCallback OnNextDiff { get; set; }
    [Parameter] public EventCallback OnSwap { get; set; }
    [Parameter] public EventCallback OnRefresh { get; set; }
    [Parameter] public EventCallback OnExportReport { get; set; }
    [Parameter] public EventCallback<bool> OnIgnoreWhitespaceChanged { get; set; }
    [Parameter] public EventCallback<bool> OnIgnoreCaseChanged { get; set; }
    [Parameter] public EventCallback<bool> OnScrollSyncChanged { get; set; }

    // ── Lifecycle ──

    protected override void OnInitialized()
    {
        _containerId = ContainerId ?? $"monaco-diff-{Guid.NewGuid():N}";
    }

    protected override async Task OnAfterRenderAsync(bool firstRender)
    {
        if (firstRender && !IsLoading && !HasError)
        {
            await InitializeDiffEditorAsync();
        }
    }

    private async Task InitializeDiffEditorAsync()
    {
        try
        {
            var opts = new
            {
                language = Language,
                theme = Theme,
                readOnly = ReadOnly,
                fontSize = FontSize,
                fontFamily = FontFamily,
                wordWrap = WordWrap,
                lineNumbers = ShowLineNumbers,
                minimap = ShowMinimap,
                renderSideBySide = ViewMode == DiffViewMode.SideBySide,
                ignoreTrimWhitespace = IgnoreTrimWhitespace,
                hideUnchangedRegions = !ShowUnchangedLines,
                revealLineCount = 20,
                minimumLineCount = 10
            };

            await JS.InvokeVoidAsync($"{MonacoModule}.createDiffEditor", _containerId, OriginalContent, ModifiedContent, opts);
            _editorCreated = true;

            // Refresh diff stats
            await RefreshDiffStatsAsync();
            StateHasChanged();
        }
        catch (Exception ex)
        {
            HasError = true;
            ErrorMessage = $"Failed to initialize diff editor: {ex.Message}";
            StateHasChanged();
        }
    }

    private async Task RefreshDiffStatsAsync()
    {
        if (!_editorCreated) return;
        try
        {
            var stats = await JS.InvokeAsync<DiffStats?>($"{MonacoModule}.getDiffStats", _containerId);
            if (stats is not null)
            {
                TotalDifferences = stats.TotalDifferences;
                Additions = stats.Additions;
                Deletions = stats.Deletions;
                Modifications = stats.Modifications;

                var totalLines = (OriginalContent?.Split('\n').Length ?? 0) +
                                 (ModifiedContent?.Split('\n').Length ?? 0);
                if (totalLines > 0)
                {
                    var changedLines = stats.Additions + stats.Deletions + stats.Modifications;
                    PercentageChanged = Math.Round((double)changedLines / totalLines * 100, 1);
                }

                var totalLen = (OriginalContent?.Length ?? 0) + (ModifiedContent?.Length ?? 0);
                if (totalLen > 0)
                {
                    var maxLen = Math.Max(OriginalContent?.Length ?? 0, ModifiedContent?.Length ?? 0);
                    var editDist = LevenshteinDistance(OriginalContent ?? "", ModifiedContent ?? "");
                    SimilarityPercentage = maxLen > 0
                        ? Math.Round((1.0 - (double)editDist / maxLen) * 100, 1)
                        : 100.0;
                }
            }
        }
        catch
        {
            // Editor may not be ready yet
        }
    }

    // ── Public methods ──

    /// <summary>
    /// Forces the diff editor to re-measure and layout.
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
    /// Navigates to the next diff.
    /// </summary>
    public async Task NavigateNextAsync()
    {
        if (_editorCreated)
        {
            try
            {
                await JS.InvokeVoidAsync($"{MonacoModule}.navigateDiff", _containerId, "next");
                CurrentDifference = Math.Min(CurrentDifference + 1, TotalDifferences);
                StateHasChanged();
            }
            catch { /* ignore */ }
        }
    }

    /// <summary>
    /// Navigates to the previous diff.
    /// </summary>
    public async Task NavigatePreviousAsync()
    {
        if (_editorCreated)
        {
            try
            {
                await JS.InvokeVoidAsync($"{MonacoModule}.navigateDiff", _containerId, "previous");
                CurrentDifference = Math.Max(CurrentDifference - 1, 1);
                StateHasChanged();
            }
            catch { /* ignore */ }
        }
    }

    /// <summary>
    /// Swaps the original and modified content.
    /// </summary>
    public async Task SwapAsync()
    {
        if (_editorCreated)
        {
            try
            {
                await JS.InvokeVoidAsync($"{MonacoModule}.swapDiff", _containerId);
                StateHasChanged();
            }
            catch { /* ignore */ }
        }
    }

    /// <summary>
    /// Toggles between side-by-side and inline view.
    /// </summary>
    public async Task ToggleViewModeAsync(DiffViewMode mode)
    {
        if (_editorCreated)
        {
            try
            {
                ViewMode = mode;
                await JS.InvokeVoidAsync($"{MonacoModule}.toggleDiffViewMode", _containerId, mode == DiffViewMode.SideBySide);
                StateHasChanged();
            }
            catch { /* ignore */ }
        }
    }

    // ── Dispose ──

    public async ValueTask DisposeAsync()
    {
        if (_editorCreated)
        {
            try { await JS.InvokeVoidAsync($"{MonacoModule}.disposeEditor", _containerId); }
            catch { /* ignore */ }
        }
    }

    // ── Simple Levenshtein distance for similarity calculation ──

    private static int LevenshteinDistance(string a, string b)
    {
        if (string.IsNullOrEmpty(a)) return b?.Length ?? 0;
        if (string.IsNullOrEmpty(b)) return a.Length;

        var lenA = a.Length;
        var lenB = b.Length;
        var d = new int[lenA + 1, lenB + 1];

        for (var i = 0; i <= lenA; i++) d[i, 0] = i;
        for (var j = 0; j <= lenB; j++) d[0, j] = j;

        for (var i = 1; i <= lenA; i++)
        {
            for (var j = 1; j <= lenB; j++)
            {
                var cost = a[i - 1] == b[j - 1] ? 0 : 1;
                d[i, j] = Math.Min(
                    Math.Min(d[i - 1, j] + 1, d[i, j - 1] + 1),
                    d[i - 1, j - 1] + cost);
            }
        }
        return d[lenA, lenB];
    }

    // ── Internal DTO for diff stats ──

    private class DiffStats
    {
        public int TotalDifferences { get; set; }
        public int Additions { get; set; }
        public int Deletions { get; set; }
        public int Modifications { get; set; }
        public object[]? Changes { get; set; }
    }
}