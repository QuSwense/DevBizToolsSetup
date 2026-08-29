using Microsoft.AspNetCore.Components;

namespace OrbitHub.Dashboard.UI.Components;

/// <summary>
/// Code-behind for the ExecutionStats component.
/// </summary>
public partial class ExecutionStats
{
    private bool _showDatePicker;
    private DateTime? _selectedDate;

    /// <summary>
    /// Gets or sets the card title.
    /// </summary>
    [Parameter] public string Title { get; set; } = "Executions";

    /// <summary>
    /// Gets or sets the total number of executions.
    /// </summary>
    [Parameter] public int TotalExecutions { get; set; }

    /// <summary>
    /// Gets or sets the pass rate percentage.
    /// </summary>
    [Parameter] public int PassRate { get; set; }

    /// <summary>
    /// Gets or sets the number of failed executions.
    /// </summary>
    [Parameter] public int FailCount { get; set; }

    /// <summary>
    /// Gets or sets whether the per-test-suite breakdown is shown in this card.
    /// </summary>
    [Parameter] public bool ShowSuiteBreakdown { get; set; } = true;

    /// <summary>
    /// Gets or sets the per-suite execution stats rendered when the breakdown is shown.
    /// </summary>
    [Parameter] public IReadOnlyList<SuiteExecStat> SuiteStats { get; set; } = Array.Empty<SuiteExecStat>();

    /// <summary>
    /// Represents per-suite execution statistics.
    /// </summary>
    public record SuiteExecStat(string Name, int Passing, int Total);

    private string SuiteBreakdownTitle =>
        ShowSuiteBreakdown ? "Hide per-suite breakdown" : "Show per-suite breakdown";

    private void ToggleSuiteBreakdown() => ShowSuiteBreakdown = !ShowSuiteBreakdown;

    private void ToggleDatePicker() => _showDatePicker = !_showDatePicker;
    private void CloseDatePicker() => _showDatePicker = false;
    private void ClearDateFilter()
    {
        _selectedDate = null;
        _showDatePicker = false;
    }
}
