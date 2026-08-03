using Microsoft.AspNetCore.Components;
using ServiceHubEnterprise.Dashboard.Application.DTOs;
using ServiceHubEnterprise.Ui.Models;

namespace ServiceHubEnterprise.Dashboard.UI.Components;

/// <summary>
/// Code-behind for the RestAppsOverview section card.
/// Shows REST app totals, request files per app, and execution success/failure over a date range.
/// </summary>
public partial class RestAppsOverview
{
    /// <summary>
    /// Gets or sets the list of REST applications.
    /// </summary>
    [Parameter] public IReadOnlyList<RestAppDto> Apps { get; set; } = Array.Empty<RestAppDto>();

    /// <summary>
    /// Gets or sets the list of REST request files.
    /// </summary>
    [Parameter] public IReadOnlyList<RequestFileDto> RequestFiles { get; set; } = Array.Empty<RequestFileDto>();

    /// <summary>
    /// Gets or sets the request-file execution history.
    /// </summary>
    [Parameter] public IReadOnlyList<RequestExecutionDto> Executions { get; set; } = Array.Empty<RequestExecutionDto>();

    /// <summary>
    /// Gets or sets whether the card is collapsed to its summary view.
    /// </summary>
    [Parameter] public bool Collapsed { get; set; }

    /// <summary>
    /// Invoked when the card's collapse state is toggled.
    /// </summary>
    [Parameter] public EventCallback<bool> OnToggle { get; set; }

    private DateRange _range = DateRange.LastDays(7);

    private void ApplyRange(DateRange? range) => _range = range ?? DateRange.LastDays(7);

    private static DateTime? TryParseTimestamp(string value)
        => DateTime.TryParse(value, out var dt) ? dt : null;

    private IEnumerable<RequestExecutionDto> FilteredExecutions =>
        Executions.Where(e => e.AppType.Equals("rest", StringComparison.OrdinalIgnoreCase)
            && TryParseTimestamp(e.ExecutedAt) is DateTime dt && _range.Includes(dt));

    private int TotalApps => Apps.Count;
    private int EnabledApps => Apps.Count(a => a.Status.Equals("enabled", StringComparison.OrdinalIgnoreCase));
    private int DisabledApps => TotalApps - EnabledApps;
    private int FilesTotal => RequestFiles.Count;
    private int FilesActive => RequestFiles.Count(f => f.Status.Equals("active", StringComparison.OrdinalIgnoreCase));
    private int ExecCount => FilteredExecutions.Count();
    private int SuccessCount => FilteredExecutions.Count(e => e.Status.Equals("success", StringComparison.OrdinalIgnoreCase));
    private int FailCount => ExecCount - SuccessCount;

    /// <summary>
    /// Represents a per-application summary row.
    /// </summary>
    public record RestAppRow(string Name, bool Enabled, int FilesActive, int FilesTotal, int Executions, int Success, int SuccessPct);

    private IReadOnlyList<RestAppRow> Rows =>
        Apps.Select(a =>
        {
            var files = RequestFiles.Where(f => f.AppName.Equals(a.Name, StringComparison.OrdinalIgnoreCase)).ToList();
            var execs = FilteredExecutions.Where(e => e.AppName.Equals(a.Name, StringComparison.OrdinalIgnoreCase)).ToList();
            var success = execs.Count(e => e.Status.Equals("success", StringComparison.OrdinalIgnoreCase));

            return new RestAppRow(
                a.Name,
                a.Status.Equals("enabled", StringComparison.OrdinalIgnoreCase),
                files.Count(f => f.Status.Equals("active", StringComparison.OrdinalIgnoreCase)),
                files.Count,
                execs.Count,
                success,
                execs.Count > 0 ? success * 100 / execs.Count : 0);
        }).ToList();
}
