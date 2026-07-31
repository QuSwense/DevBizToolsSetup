namespace ServiceHubEnterprise.SoapApplications.Services;

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

/// <summary>
/// Singleton store for request-file execution history, filtered to SOAP applications.
/// Reads the shared mock_db/request-executions.json (same source the Dashboard uses).
/// </summary>
public class RequestExecutionStore
{
    /// <summary>
    /// All SOAP executions, ordered newest-first.
    /// </summary>
    public SoapExecution[] SoapExecutions { get; private set; }

    public RequestExecutionStore(MockDbLoader loader)
    {
        var all = loader.LoadJsonAsync<SoapExecution[]>("request-executions.json")
            .GetAwaiter().GetResult() ?? [];

        SoapExecutions = all
            .Where(e => e.AppType.Equals("soap", StringComparison.OrdinalIgnoreCase))
            .OrderByDescending(e => e.ExecutedAt)
            .ToArray();
    }
}
