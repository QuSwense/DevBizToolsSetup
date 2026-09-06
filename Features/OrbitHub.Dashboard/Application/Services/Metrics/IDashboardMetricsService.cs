using OrbitHub.Dashboard.Application.DTOs;

namespace OrbitHub.Dashboard.Application.Services.Metrics;

/// <summary>
/// Provides the aggregate KPI metrics shown on the dashboard overview.
/// </summary>
public interface IDashboardMetricsService
{
    /// <summary>
    /// Retrieves the aggregate metrics for the dashboard overview.
    /// </summary>
    Task<DashboardMetricsDto> GetMetricsAsync();
}
