namespace ServiceHubEnterprise.SoapApplications.Models;

/// <summary>
/// Represents a single execution of a SOAP request file (from request-executions.json).
/// Timestamps are stored as strings ("yyyy-MM-dd HH:mm:ss") because System.Text.Json
/// does not parse the space-separated format directly into DateTime.
/// </summary>
public record SoapExecution(
    string Id,
    string AppName,
    string AppType,
    string FileName,
    string Status,
    string ExecutedAt,
    long DurationMs,
    string TriggeredBy)
{
    /// <summary>
    /// Attempts to parse the stored timestamp into a DateTime.
    /// </summary>
    public DateTime? TryGetTimestamp()
        => DateTime.TryParse(ExecutedAt, out var dt) ? dt : null;
}
