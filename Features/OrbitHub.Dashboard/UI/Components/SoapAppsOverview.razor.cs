using Microsoft.AspNetCore.Components;
using OrbitHub.Dashboard.Application.DTOs;
using OrbitHub.Ui.Models;

namespace OrbitHub.Dashboard.UI.Components;

/// <summary>
/// Code-behind for the SoapAppsOverview section card.
/// Shows SOAP app totals, WSDL sync status, request files per app, and execution stats over a date range.
/// </summary>
public partial class SoapAppsOverview
{
    /// <summary>
    /// Gets or sets the list of SOAP applications.
    /// </summary>
    [Parameter] public IReadOnlyList<SoapAppDto> Apps { get; set; } = Array.Empty<SoapAppDto>();

    /// <summary>
    /// Gets or sets the list of SOAP request files.
    /// </summary>
    [Parameter] public IReadOnlyList<RequestFileDto> RequestFiles { get; set; } = Array.Empty<RequestFileDto>();

    /// <summary>
    /// Gets or sets the WSDL sync records.
    /// </summary>
    [Parameter] public IReadOnlyList<WsdlRecordDto> WsdlRecords { get; set; } = Array.Empty<WsdlRecordDto>();

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
        Executions.Where(e => e.AppType.Equals("soap", StringComparison.OrdinalIgnoreCase)
            && TryParseTimestamp(e.ExecutedAt) is DateTime dt && _range.Includes(dt));

    private int TotalApps => Apps.Count;
    private int EnabledApps => Apps.Count(a => a.Status.Equals("enabled", StringComparison.OrdinalIgnoreCase));
    private int DisabledApps => TotalApps - EnabledApps;
    private int WsdlSynced => WsdlRecords.Count(w => w.Status.Equals("synced", StringComparison.OrdinalIgnoreCase));
    private int WsdlTotal => WsdlRecords.Count;
    private int FilesTotal => RequestFiles.Count;
    private int FilesActive => RequestFiles.Count(f => f.Status.Equals("active", StringComparison.OrdinalIgnoreCase));
    private int ExecCount => FilteredExecutions.Count();
    private int SuccessCount => FilteredExecutions.Count(e => e.Status.Equals("success", StringComparison.OrdinalIgnoreCase));
    private int FailCount => ExecCount - SuccessCount;

    /// <summary>
    /// Represents a per-application summary row.
    /// </summary>
    public record SoapAppRow(string Name, bool Enabled, string WsdlStatus, string LastSync, int FilesActive, int FilesTotal, int Executions, int Success, int SuccessPct);

    private IReadOnlyList<SoapAppRow> Rows =>
        [.. Apps.Select(a =>
        {
            var records = WsdlRecords.Where(w => w.AppName.Equals(a.Name, StringComparison.OrdinalIgnoreCase)).ToList();
            var files = RequestFiles.Where(f => f.AppName.Equals(a.Name, StringComparison.OrdinalIgnoreCase)).ToList();
            var execs = FilteredExecutions.Where(e => e.AppName.Equals(a.Name, StringComparison.OrdinalIgnoreCase)).ToList();
            var success = execs.Count(e => e.Status.Equals("success", StringComparison.OrdinalIgnoreCase));

            var lastSync = records
                .Select(r => TryParseTimestamp(r.UploadedAt))
                .Where(d => d.HasValue)
                .DefaultIfEmpty()
                .Max();

            var wsdlStatus = records.Any(r => r.Status.Equals("synced", StringComparison.OrdinalIgnoreCase)) ? "Synced"
                : records.Any(r => r.Status.Equals("parsing", StringComparison.OrdinalIgnoreCase)) ? "Parsing"
                : records.Any(r => r.Status.Equals("failed", StringComparison.OrdinalIgnoreCase)) ? "Failed"
                : "—";

            return new SoapAppRow(
                a.Name,
                a.Status.Equals("enabled", StringComparison.OrdinalIgnoreCase),
                wsdlStatus,
                lastSync.HasValue ? lastSync.Value.ToString("MMM dd") : "—",
                files.Count(f => f.Status.Equals("active", StringComparison.OrdinalIgnoreCase)),
                files.Count,
                execs.Count,
                success,
                execs.Count > 0 ? success * 100 / execs.Count : 0);
        })];

    private string WsdlBadgeClass(string status) => status switch
    {
        "Synced" => "sb-synced",
        "Parsing" => "sb-parsing",
        "Failed" => "sb-failed",
        _ => "sb-none"
    };
}
