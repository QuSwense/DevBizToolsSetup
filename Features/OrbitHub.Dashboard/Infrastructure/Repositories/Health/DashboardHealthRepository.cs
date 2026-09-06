using OrbitHub.Dashboard.Core.Entities;
using OrbitHub.Dashboard.Core.Interfaces.Health;

namespace OrbitHub.Dashboard.Infrastructure.Repositories.Health;

/// <summary>
/// Reads the service health monitoring data.
/// No service-health tables exist in the schema yet, so every section returns empty.
/// </summary>
internal sealed class DashboardHealthRepository : IDashboardHealthRepository
{
    /// <inheritdoc />
    public Task<IReadOnlyList<ServiceHealthEntity>> GetServiceHealthAsync()
    {
        // No service-health table exists in the schema yet.
        return Task.FromResult<IReadOnlyList<ServiceHealthEntity>>(Array.Empty<ServiceHealthEntity>());
    }

    /// <inheritdoc />
    public Task<IReadOnlyList<ServiceUptimeEntity>> GetServiceUptimeAsync()
    {
        // No service-uptime table exists in the schema yet.
        return Task.FromResult<IReadOnlyList<ServiceUptimeEntity>>(Array.Empty<ServiceUptimeEntity>());
    }
}
