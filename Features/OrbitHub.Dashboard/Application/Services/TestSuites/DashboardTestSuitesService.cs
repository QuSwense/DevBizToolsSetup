using OrbitHub.Dashboard.Application.DTOs;
using OrbitHub.Dashboard.Core.Interfaces.TestSuites;

namespace OrbitHub.Dashboard.Application.Services.TestSuites;

/// <summary>
/// Provides the test suite data by reading from the test suites repository.
/// </summary>
internal sealed class DashboardTestSuitesService(IDashboardTestSuitesRepository repository) : IDashboardTestSuitesService
{
    private readonly IDashboardTestSuitesRepository _repository = repository;

    /// <inheritdoc />
    public async Task<IReadOnlyList<TestSuiteDto>> GetTestSuitesAsync()
    {
        var entities = await _repository.GetTestSuitesAsync();

        return [.. entities
            .Select(e => new TestSuiteDto
            {
                Name = e.Name,
                TotalCases = e.TotalCases,
                PassingCases = e.PassingCases,
                TotalFiles = e.TotalFiles
            })];
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<TestSuiteHistoryDto>> GetTestSuiteHistoryAsync()
    {
        var entities = await _repository.GetTestSuiteHistoryAsync();

        return [.. entities
            .Select(e => new TestSuiteHistoryDto
            {
                Id = e.Id,
                SuiteName = e.SuiteName,
                ExecutedAt = e.ExecutedAt,
                Status = e.Status,
                TotalCases = e.TotalCases,
                PassingCases = e.PassingCases,
                DurationMs = e.DurationMs
            })];
    }
}
