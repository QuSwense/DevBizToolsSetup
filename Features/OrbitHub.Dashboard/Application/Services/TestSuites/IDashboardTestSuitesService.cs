using OrbitHub.Dashboard.Application.DTOs;

namespace OrbitHub.Dashboard.Application.Services.TestSuites;

/// <summary>
/// Provides the test suite catalog and the historical suite runs surfaced on the dashboard.
/// </summary>
public interface IDashboardTestSuitesService
{
    /// <summary>
    /// Retrieves all test suite summaries.
    /// </summary>
    Task<IReadOnlyList<TestSuiteDto>> GetTestSuitesAsync();

    /// <summary>
    /// Retrieves the historical runs of the test suites.
    /// </summary>
    Task<IReadOnlyList<TestSuiteHistoryDto>> GetTestSuiteHistoryAsync();
}
