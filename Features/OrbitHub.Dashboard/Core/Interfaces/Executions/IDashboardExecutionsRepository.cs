using OrbitHub.Dashboard.Core.Entities;

namespace OrbitHub.Dashboard.Core.Interfaces.Executions;

/// <summary>
/// Reads the request-file execution history surfaced on the dashboard.
/// </summary>
public interface IDashboardExecutionsRepository
{
    /// <summary>
    /// Retrieves the request-file execution history (REST and SOAP).
    /// </summary>
    Task<IReadOnlyList<RequestExecutionEntity>> GetRequestExecutionsAsync();
}
