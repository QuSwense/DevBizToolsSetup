using Microsoft.Extensions.DependencyInjection;
using OrbitHub.FileManagement.Services;

namespace OrbitHub.FileManagement.DependencyInjection;

/// <summary>
/// Extension methods for registering File Management feature services.
/// </summary>
public static class ServiceCollectionExtensions
{
    /// <summary>
    /// Adds the File Management feature services to the service collection.
    /// </summary>
    public static IServiceCollection AddFileManagementFeature(this IServiceCollection services)
    {
        services.AddSingleton<FileStore>();
        return services;
    }
}