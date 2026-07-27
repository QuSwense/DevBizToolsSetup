using Microsoft.Extensions.DependencyInjection;

namespace ServiceHubEnterprise.FileManagement;

/// <summary>
/// Extension methods for registering File Management feature services.
/// </summary>
public static class DependencyInjection
{
    /// <summary>
    /// Adds the File Management feature services to the service collection.
    /// </summary>
    public static IServiceCollection AddFileManagementFeature(this IServiceCollection services)
    {
        // Register File Management-specific services here
        return services;
    }
}
