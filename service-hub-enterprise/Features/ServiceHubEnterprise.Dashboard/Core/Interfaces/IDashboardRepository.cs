using ServiceHubEnterprise.Dashboard.Core.Entities;

namespace ServiceHubEnterprise.Dashboard.Core.Interfaces;

/// <summary>
/// Defines the contract for dashboard data persistence.
/// </summary>
public interface IDashboardRepository
{
    /// <summary>
    /// Retrieves all service health entities.
    /// </summary>
    Task<IReadOnlyList<ServiceHealthEntity>> GetServiceHealthAsync();

    /// <summary>
    /// Retrieves all test suite entities.
    /// </summary>
    Task<IReadOnlyList<TestSuiteEntity>> GetTestSuitesAsync();
}
