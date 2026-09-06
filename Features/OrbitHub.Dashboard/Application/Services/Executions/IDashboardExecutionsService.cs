using OrbitHub.Dashboard.Application.DTOs;

namespace OrbitHub.Dashboard.Application.Services.Executions;

/// <summary>
/// Provides the request-file execution history surfaced on the dashboard.
/// </summary>
public interface IDashboardExecutionsService
{
    /// <summary>
    /// Retrieves the request-file execution history (REST and SOAP).
    /// </summary>
    Task<IReadOnlyList<RequestExecutionDto>> GetRequestExecutionsAsync();
}
