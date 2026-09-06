using OrbitHub.Dashboard.Core.Entities;

namespace OrbitHub.Dashboard.Core.Interfaces.TestSuites;

/// <summary>
/// Reads the test suite catalog and the historical suite runs surfaced on the dashboard.
/// </summary>
public interface IDashboardTestSuitesRepository
{
    /// <summary>
    /// Retrieves all test suite entities.
    /// </summary>
    Task<IReadOnlyList<TestSuiteEntity>> GetTestSuitesAsync();

    /// <summary>
    /// Retrieves the historical runs of the test suites.
    /// </summary>
    Task<IReadOnlyList<TestSuiteHistoryEntity>> GetTestSuiteHistoryAsync();
}
