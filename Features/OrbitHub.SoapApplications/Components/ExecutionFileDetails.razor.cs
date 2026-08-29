using Microsoft.AspNetCore.Components;
using OrbitHub.SoapApplications.Models;

namespace OrbitHub.SoapApplications.Components;

/// <summary>
/// Per-file execution detail panel: Request / Response / Parsed fields /
/// Extractions / Logs tabs for a single file inside an execution group.
/// </summary>
public partial class ExecutionFileDetails
{
    /// <summary>The execution group the file belongs to (for context display).</summary>
    [Parameter] public SoapExecutionGroup? Group { get; set; }

    /// <summary>The execution file whose details are shown.</summary>
    [Parameter] public SoapExecutionFile? File { get; set; }

    private string _activeTab = "request";

    private void SetActiveTab(string tab)
        => _activeTab = tab;

    private static (string Css, string Label) StatusBadge(string status) => status switch
    {
        "success" => ("status-enabled", "Success"),
        "failed" => ("status-down", "Failed"),
        "running" => ("status-warn", "Running"),
        _ => ("status-disabled", "Queued")
    };

    private static string LogTypeBadge(string type) => type switch
    {
        "warning" => "log-warning",
        "error" => "log-error",
        "request" => "log-request",
        "response" => "log-response",
        "assertion" => "log-assertion",
        _ => "log-info"
    };

    private static string FormatDuration(long ms)
        => ms < 1000 ? $"{ms} ms" : $"{ms / 1000.0:0.0}s";
}
