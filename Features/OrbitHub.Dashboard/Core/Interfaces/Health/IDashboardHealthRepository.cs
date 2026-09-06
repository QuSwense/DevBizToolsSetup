using OrbitHub.Dashboard.Core.Entities;

namespace OrbitHub.Dashboard.Core.Interfaces.Health;

/// <summary>
/// Reads the service health and uptime monitoring data surfaced on the dashboard.
/// </summary>
public interface IDashboardHealthRepository
{
    /// <summary>
    /// Retrieves all service health entities.
    /// </summary>
    Task<IReadOnlyList<ServiceHealthEntity>> GetServiceHealthAsync();

    /// <summary>
    /// Retrieves the time-series service health samples.
    /// </summary>
    Task<IReadOnlyList<ServiceUptimeEntity>> GetServiceUptimeAsync();
}
