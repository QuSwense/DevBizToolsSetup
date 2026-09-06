using OrbitHub.Dashboard.Application.DTOs;

namespace OrbitHub.Dashboard.Application.Services.Health;

/// <summary>
/// Provides the service health and uptime monitoring data surfaced on the dashboard.
/// </summary>
public interface IDashboardHealthService
{
    /// <summary>
    /// Retrieves all service health entries.
    /// </summary>
    Task<IReadOnlyList<ServiceHealthDto>> GetServiceHealthAsync();

    /// <summary>
    /// Retrieves the time-series service health samples.
    /// </summary>
    Task<IReadOnlyList<ServiceUptimeDto>> GetServiceUptimeAsync();
}
