using Microsoft.AspNetCore.Components;
using ServiceHubEnterprise.Dashboard.Application.DTOs;

namespace ServiceHubEnterprise.Dashboard.UI.Components;

/// <summary>
/// Code-behind for the TestSuitesOverview section card.
/// Shows current suite status and per-suite run history with a selection filter.
/// </summary>
public partial class TestSuitesOverview
{
    /// <summary>
    /// Gets or sets the current test suite summaries.
    /// </summary>
    [Parameter] public IReadOnlyList<TestSuiteDto> Suites { get; set; } = Array.Empty<TestSuiteDto>();

    /// <summary>
    /// Gets or sets the historical test suite runs.
    /// </summary>
    [Parameter] public IReadOnlyList<TestSuiteHistoryDto> History { get; set; } = Array.Empty<TestSuiteHistoryDto>();

    private string? _selectedSuite;

    private IReadOnlyList<string> SuiteNames => Suites.Select(s => s.Name).ToList();

    private string SelectedSuite => _selectedSuite ?? string.Empty;

    /// <inheritdoc />
    protected override void OnParametersSet()
    {
        if (_selectedSuite is null || !SuiteNames.Contains(_selectedSuite))
        {
            _selectedSuite = SuiteNames.FirstOrDefault();
        }
    }

    private int TotalSuites => Suites.Count;
    private int TotalCases => Suites.Sum(s => s.TotalCases);
    private int PassingCases => Suites.Sum(s => s.PassingCases);

    private static int PctFor(TestSuiteDto s) => s.TotalCases > 0 ? s.PassingCases * 100 / s.TotalCases : 0;

    private string StatusFor(TestSuiteDto s) =>
        s.TotalCases > 0 && s.PassingCases == s.TotalCases ? "Passed"
        : s.PassingCases == 0 ? "Failed"
        : "In Progress";

    private string StatusBadgeClass(string status) => status switch
    {
        "Passed" => "sb-passed",
        "Failed" => "sb-failed",
        _ => "sb-running"
    };

    private static DateTime? TryParseTimestamp(string value)
        => DateTime.TryParse(value, out var dt) ? dt : null;

    private IReadOnlyList<TestSuiteHistoryDto> SelectedRuns =>
        History
            .Where(h => h.SuiteName.Equals(SelectedSuite, StringComparison.OrdinalIgnoreCase))
            .OrderByDescending(h => TryParseTimestamp(h.ExecutedAt))
            .ToList();

    private int RunsCount => SelectedRuns.Count;
    private string LastResult => SelectedRuns.FirstOrDefault()?.Status ?? "—";
    private string LastRunDate => SelectedRuns.FirstOrDefault() is { } r && TryParseTimestamp(r.ExecutedAt) is { } d
        ? d.ToString("MMM dd, HH:mm")
        : "—";
    private string AvgDuration => SelectedRuns.Count > 0
        ? FormatDuration((int)SelectedRuns.Average(r => r.DurationMs))
        : "—";

    private string SelectedRunBadge(string status) => status switch
    {
        "passed" => "sb-passed",
        "failed" => "sb-failed",
        _ => "sb-running"
    };

    private static string FormatDuration(int ms)
    {
        var t = TimeSpan.FromMilliseconds(ms);
        return t.TotalMinutes >= 1 ? $"{(int)t.TotalMinutes}m {t.Seconds}s" : $"{t.Seconds}s";
    }
}
