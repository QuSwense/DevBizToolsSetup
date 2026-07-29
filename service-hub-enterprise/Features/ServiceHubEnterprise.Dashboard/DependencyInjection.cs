using Microsoft.Extensions.DependencyInjection;

namespace ServiceHubEnterprise.Dashboard;

/// <summary>
/// Extension methods for registering Dashboard feature services.
/// </summary>
public static class DependencyInjection
{
    /// <summary>
    /// Adds the Dashboard feature services to the service collection.
    /// </summary>
    public static IServiceCollection AddDashboardFeature(this IServiceCollection services)
    {
        // Register Dashboard-specific services here
        // e.g., services.AddScoped<IDashboardService, DashboardService>();
        return services;
    }
}
