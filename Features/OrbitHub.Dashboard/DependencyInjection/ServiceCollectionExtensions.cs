using Microsoft.Extensions.DependencyInjection;
using OrbitHub.Dashboard.Application.Services;
using OrbitHub.Dashboard.Application.Services.Applications;
using OrbitHub.Dashboard.Application.Services.Assets;
using OrbitHub.Dashboard.Application.Services.Executions;
using OrbitHub.Dashboard.Application.Services.Health;
using OrbitHub.Dashboard.Application.Services.Metrics;
using OrbitHub.Dashboard.Application.Services.TestSuites;
using OrbitHub.Dashboard.Application.Services.Users;
using OrbitHub.Dashboard.Core.Interfaces.Applications;
using OrbitHub.Dashboard.Core.Interfaces.Assets;
using OrbitHub.Dashboard.Core.Interfaces.Executions;
using OrbitHub.Dashboard.Core.Interfaces.Health;
using OrbitHub.Dashboard.Core.Interfaces.Metrics;
using OrbitHub.Dashboard.Core.Interfaces.TestSuites;
using OrbitHub.Dashboard.Core.Interfaces.Users;
using OrbitHub.Dashboard.Infrastructure.Repositories.Applications;
using OrbitHub.Dashboard.Infrastructure.Repositories.Assets;
using OrbitHub.Dashboard.Infrastructure.Repositories.Executions;
using OrbitHub.Dashboard.Infrastructure.Repositories.Health;
using OrbitHub.Dashboard.Infrastructure.Repositories.Metrics;
using OrbitHub.Dashboard.Infrastructure.Repositories.TestSuites;
using OrbitHub.Dashboard.Infrastructure.Repositories.Users;

namespace OrbitHub.Dashboard;

/// <summary>
/// Extension methods for registering Dashboard feature services.
/// Register the entire feature with ONE method call.
/// </summary>
public static class DependencyInjection
{
    /// <summary>
    /// Adds the Dashboard feature services to the service collection.
    /// Registers the grouped repositories, the grouped services, and the orchestrator.
    /// </summary>
    public static IServiceCollection AddDashboardFeature(this IServiceCollection services)
    {
        // Infrastructure — grouped repositories (singletons; each call opens its own DI scope)
        services.AddSingleton<IDashboardMetricsRepository, DashboardMetricsRepository>();
        services.AddSingleton<IDashboardApplicationsRepository, DashboardApplicationsRepository>();
        services.AddSingleton<IDashboardAssetsRepository, DashboardAssetsRepository>();
        services.AddSingleton<IDashboardUsersRepository, DashboardUsersRepository>();
        services.AddSingleton<IDashboardTestSuitesRepository, DashboardTestSuitesRepository>();
        services.AddSingleton<IDashboardExecutionsRepository, DashboardExecutionsRepository>();
        services.AddSingleton<IDashboardHealthRepository, DashboardHealthRepository>();

        // Application — grouped services
        services.AddScoped<IDashboardMetricsService, DashboardMetricsService>();
        services.AddScoped<IDashboardApplicationsService, DashboardApplicationsService>();
        services.AddScoped<IDashboardAssetsService, DashboardAssetsService>();
        services.AddScoped<IDashboardUsersService, DashboardUsersService>();
        services.AddScoped<IDashboardTestSuitesService, DashboardTestSuitesService>();
        services.AddScoped<IDashboardExecutionsService, DashboardExecutionsService>();
        services.AddScoped<IDashboardHealthService, DashboardHealthService>();

        // Application — orchestrator consumed by the dashboard page
        services.AddScoped<IDashboardService, DashboardService>();

        return services;
    }
}
