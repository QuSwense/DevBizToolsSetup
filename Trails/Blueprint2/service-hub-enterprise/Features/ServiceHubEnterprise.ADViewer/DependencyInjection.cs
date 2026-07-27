using Microsoft.Extensions.DependencyInjection;

namespace ServiceHubEnterprise.ADViewer;

/// <summary>
/// Extension methods for registering AD Viewer feature services.
/// </summary>
public static class DependencyInjection
{
    /// <summary>
    /// Adds the AD Viewer feature services to the service collection.
    /// </summary>
    public static IServiceCollection AddADViewerFeature(this IServiceCollection services)
    {
        // Register AD Viewer-specific services here
        return services;
    }
}
