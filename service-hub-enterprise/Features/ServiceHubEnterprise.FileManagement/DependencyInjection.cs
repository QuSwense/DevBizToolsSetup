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
        // FileManagementDbContext is registered in Program.cs (shared SQLite database)
        return services;
    }
}
