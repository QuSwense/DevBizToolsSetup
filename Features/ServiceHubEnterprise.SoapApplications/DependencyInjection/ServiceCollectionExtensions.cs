using Microsoft.Extensions.DependencyInjection;
using ServiceHubEnterprise.SoapApplications.Services;
using ServiceHubEnterprise.SoapApplications.Services.Execution;

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
        // MockDbLoader is kept for backward compatibility but retired from active use.
        // Stores now use the SQLite database via SoapDbContext (registered in Program.cs).
        services.AddSingleton<MockDbLoader>();
        services.AddSingleton<SoapAppStore>();
        services.AddSingleton<WsdlSyncStore>();
        services.AddSingleton<RequestExecutionStore>();
        services.AddSingleton<SoapExecutionStore>();
        services.AddSingleton<SoapTestCaseStore>();
        services.AddSingleton<IExecutionEngine, SimulatedSoapExecutionEngine>();
        return services;
    }
}
