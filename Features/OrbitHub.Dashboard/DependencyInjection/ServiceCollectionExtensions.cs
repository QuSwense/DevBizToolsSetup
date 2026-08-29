using Microsoft.Extensions.DependencyInjection;
using OrbitHub.Dashboard.Application.Services;
using OrbitHub.Dashboard.Core.Interfaces;
using OrbitHub.Dashboard.Infrastructure.Repositories;

namespace OrbitHub.Dashboard;

/// <summary>
/// Extension methods for registering Dashboard feature services.
/// Register the entire feature with ONE method call.
/// </summary>
public static class DependencyInjection
{
    /// <summary>
    /// Adds the Dashboard feature services to the service collection.
    /// Registers repository, services, and all infrastructure.
    /// </summary>
    public static IServiceCollection AddDashboardFeature(this IServiceCollection services)
    {
        // Infrastructure
        services.AddSingleton<IDashboardRepository, DashboardRepository>();

        // Application
        services.AddScoped<IDashboardService, DashboardService>();

        return services;
    }
}
