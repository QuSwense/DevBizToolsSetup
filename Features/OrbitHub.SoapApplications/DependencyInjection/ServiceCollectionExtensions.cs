using Microsoft.Extensions.DependencyInjection;
using OrbitHub.SoapApplications.Services;
using OrbitHub.SoapApplications.Services.Execution;

namespace OrbitHub.SoapApplications;

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
        // Stores use the MSSQL database via the linq2db data connections registered in Program.cs.
        services.AddSingleton<SoapAppStore>();
        services.AddSingleton<WsdlSyncStore>();
        services.AddSingleton<RequestExecutionStore>();
        services.AddSingleton<SoapExecutionStore>();
        services.AddSingleton<SoapTestCaseStore>();
        services.AddSingleton<IExecutionEngine, SimulatedSoapExecutionEngine>();
        return services;
    }
}
