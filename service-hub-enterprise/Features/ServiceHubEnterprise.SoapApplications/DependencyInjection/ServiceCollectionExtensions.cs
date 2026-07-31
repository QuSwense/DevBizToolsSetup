using Microsoft.Extensions.DependencyInjection;
using ServiceHubEnterprise.SoapApplications.Services;

namespace ServiceHubEnterprise.SoapApplications;

/// <summary>
/// Extension methods for registering SOAP Applications feature services.
/// </summary>
public static class ServiceCollectionExtensions
{
    /// <summary>
    /// Adds the SOAP Applications feature services to the service collection.
    /// </summary>
    public static IServiceCollection AddSoapApplicationsFeature(this IServiceCollection services)
    {
        services.AddSingleton<MockDbLoader>();
        services.AddSingleton<SoapAppStore>();
        services.AddSingleton<WsdlSyncStore>();
        services.AddSingleton<RequestExecutionStore>();
        return services;
    }
}
