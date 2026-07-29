using Microsoft.Extensions.DependencyInjection;

namespace ServiceHubEnterprise.SoapApplications;

/// <summary>
/// Extension methods for registering SOAP Applications feature services.
/// </summary>
public static class DependencyInjection
{
    /// <summary>
    /// Adds the SOAP Applications feature services to the service collection.
    /// </summary>
    public static IServiceCollection AddSoapApplicationsFeature(this IServiceCollection services)
    {
        // Register SOAP Applications-specific services here
        return services;
    }
}
