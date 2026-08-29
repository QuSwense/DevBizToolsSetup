namespace OrbitHub.SoapApplications.Models;

/// <summary>
/// A uniquely identified batch of request-file executions triggered together
/// (even a single-file run gets its own group id). Contains the per-file
/// execution records, logs and results.
/// </summary>
public class SoapExecutionGroup
{
    /// <summary>Unique execution-group id (e.g. "exg-..."), one per run trigger.</summary>
    public string Id { get; set; } = "";

    /// <summary>When the group started ("yyyy-MM-dd HH:mm:ss").</summary>
    public string StartedAt { get; set; } = "";

    /// <summary>When the group finished ("yyyy-MM-dd HH:mm:ss"). Null while running.</summary>
    public string? FinishedAt { get; set; }

    /// <summary>User who triggered the execution.</summary>
    public string TriggeredBy { get; set; } = "";

    /// <summary>Group status: "running" | "completed" | "failed" | "partial".</summary>
    public string Status { get; set; } = "running";

    /// <summary>Total elapsed time across the whole group in milliseconds.</summary>
    public long DurationMs { get; set; }

    /// <summary>Files executed as part of this group.</summary>
    public List<SoapExecutionFile> Files { get; set; } = [];

    /// <summary>Number of files in the group (computed, not serialized).</summary>
    public int FileCount => Files.Count;

    /// <summary>Distinct applications involved (computed, not serialized).</summary>
    public string AppsSummary => string.Join(", ", Files.Select(f => f.AppName).Distinct());
}
