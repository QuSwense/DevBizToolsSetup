using Microsoft.Extensions.DependencyInjection;

namespace ServiceHubEnterprise.MonitoringHealth;

/// <summary>
/// Extension methods for registering Monitoring Health feature services.
/// </summary>
public static class DependencyInjection
{
    /// <summary>
    /// Adds the Monitoring Health feature services to the service collection.
    /// </summary>
    public static IServiceCollection AddMonitoringHealthFeature(this IServiceCollection services)
    {
        // Register Monitoring Health-specific services here
        return services;
    }
}
