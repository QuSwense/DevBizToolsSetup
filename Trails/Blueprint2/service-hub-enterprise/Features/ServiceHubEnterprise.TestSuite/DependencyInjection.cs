using Microsoft.Extensions.DependencyInjection;

namespace ServiceHubEnterprise.TestSuite;

/// <summary>
/// Extension methods for registering Test Suite feature services.
/// </summary>
public static class DependencyInjection
{
    /// <summary>
    /// Adds the Test Suite feature services to the service collection.
    /// </summary>
    public static IServiceCollection AddTestSuiteFeature(this IServiceCollection services)
    {
        // Register Test Suite-specific services here
        return services;
    }
}
