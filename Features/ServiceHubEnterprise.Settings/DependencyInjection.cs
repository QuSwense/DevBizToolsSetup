using Microsoft.Extensions.DependencyInjection;

namespace ServiceHubEnterprise.Settings;

/// <summary>
/// Extension methods for registering Settings feature services.
/// </summary>
public static class DependencyInjection
{
    /// <summary>
    /// Adds the Settings feature services to the service collection.
    /// </summary>
    public static IServiceCollection AddSettingsFeature(this IServiceCollection services)
    {
        // Register Settings-specific services here
        return services;
    }
}
