using Microsoft.Extensions.DependencyInjection;

namespace ServiceHubEnterprise.RestApplications;

/// <summary>
/// Extension methods for registering REST Applications feature services.
/// </summary>
public static class DependencyInjection
{
    /// <summary>
    /// Adds the REST Applications feature services to the service collection.
    /// </summary>
    public static IServiceCollection AddRestApplicationsFeature(this IServiceCollection services)
    {
        // Register REST Applications-specific services here
        return services;
    }
}
