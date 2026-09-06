using OrbitHub.Dashboard.Core.Entities;

namespace OrbitHub.Dashboard.Core.Interfaces.Metrics;

/// <summary>
/// Reads the aggregate KPI metrics for the dashboard overview.
/// </summary>
public interface IDashboardMetricsRepository
{
    /// <summary>
    /// Retrieves the aggregate metrics for the dashboard overview.
    /// </summary>
    Task<DashboardMetricsEntity> GetMetricsAsync();
}
