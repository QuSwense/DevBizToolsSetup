using ServiceHubEnterprise.SoapApplications.Models;

namespace ServiceHubEnterprise.SoapApplications.Services;

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
