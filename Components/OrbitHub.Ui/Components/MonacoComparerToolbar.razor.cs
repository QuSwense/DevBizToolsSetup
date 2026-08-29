using Microsoft.AspNetCore.Components;
using OrbitHub.Ui.Models;

namespace OrbitHub.Ui.Components;

/// <summary>
/// Controls bar for the MonacoDiffEditor with navigation, diff toggles, and view mode.
/// </summary>
public partial class MonacoComparerToolbar
{
    [Parameter] public bool ShowUnchangedLinesToggle { get; set; } = true;
    [Parameter] public bool ShowWhitespaceToggles { get; set; } = true;
    [Parameter] public bool ShowCaseToggle { get; set; } = true;
    [Parameter] public bool ShowNavigation { get; set; } = true;
    [Parameter] public bool ShowDiffCounter { get; set; } = true;
    [Parameter] public bool ShowScrollSync { get; set; } = true;
    [Parameter] public bool ShowFilterByType { get; set; }
    [Parameter] public bool ShowAcceptReject { get; set; }
    [Parameter] public bool ShowViewModeToggle { get; set; } = true;
    [Parameter] public bool ShowSwapButton { get; set; } = true;
    [Parameter] public bool ShowRefreshButton { get; set; } = true;
    [Parameter] public bool ShowExportButton { get; set; } = true;

    [Parameter] public bool ShowUnchangedLines { get; set; } = true;
    [Parameter] public bool IgnoreWhitespace { get; set; }
    [Parameter] public bool IgnoreCase { get; set; }
    [Parameter] public bool ScrollSync { get; set; } = true;
    [Parameter] public EDiffViewMode ViewMode { get; set; } = EDiffViewMode.SideBySide;

    [Parameter] public int TotalDifferences { get; set; }
    [Parameter] public int CurrentDifference { get; set; }
    [Parameter] public EventCallback<int> CurrentDifferenceChanged { get; set; }

    [Parameter] public EventCallback<EDiffViewMode> OnViewModeChanged { get; set; }
    [Parameter] public EventCallback OnPreviousDiff { get; set; }
    [Parameter] public EventCallback OnNextDiff { get; set; }
    [Parameter] public EventCallback OnSwap { get; set; }
    [Parameter] public EventCallback OnRefresh { get; set; }
    [Parameter] public EventCallback OnExportReport { get; set; }
    [Parameter] public EventCallback<bool> OnShowUnchangedLinesChanged { get; set; }
    [Parameter] public EventCallback<bool> OnIgnoreWhitespaceChanged { get; set; }
    [Parameter] public EventCallback<bool> OnIgnoreCaseChanged { get; set; }
    [Parameter] public EventCallback<bool> OnScrollSyncChanged { get; set; }
}