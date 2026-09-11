using Microsoft.Extensions.DependencyInjection;
using OrbitHub.Dashboard.Core.Entities;
using OrbitHub.Dashboard.Core.Interfaces.TestSuites;
using OrbitHub.Data.TestManagement.Views;

namespace OrbitHub.Dashboard.Infrastructure.Repositories.TestSuites;

/// <summary>
/// Reads the test suite catalog and the historical suite runs through the generated
/// OrbitHub.Data view repositories (v_ServiceTestSuitesWithDetails and
/// v_ServiceTestSuiteExecutionAuditsWithDetails).
/// </summary>
internal sealed class DashboardTestSuitesRepository(IServiceProvider serviceProvider) : IDashboardTestSuitesRepository
{
    private readonly IServiceProvider _serviceProvider = serviceProvider;

    /// <inheritdoc />
    public async Task<IReadOnlyList<TestSuiteEntity>> GetTestSuitesAsync()
    {
        using var scope = _serviceProvider.CreateScope();
        var suitesView = scope.ServiceProvider.GetRequiredService<ServiceTestSuiteWithDetailsViewRepository>();

        var suites = ViewRepositoryResult.OrThrow(await suitesView.GetAllAsync());

        return [.. suites
            .Select(s => new TestSuiteEntity
            {
                Name = s.SuiteName,
                TotalCases = s.TestCaseCount,
                PassingCases = 0, // no suite-level pass/fail aggregate in the schema yet
                TotalFiles = 0    // no per-suite file count in the schema yet
            })];
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<TestSuiteHistoryEntity>> GetTestSuiteHistoryAsync()
    {
        using var scope = _serviceProvider.CreateScope();
        var auditsView = scope.ServiceProvider.GetRequiredService<ServiceTestSuiteExecutionAuditWithDetailsViewRepository>();

        var audits = ViewRepositoryResult.OrThrow(await auditsView.GetAllAsync());

        return [.. audits
            .OrderByDescending(a => a.ExecutedAt)
            .Select(a => new TestSuiteHistoryEntity
            {
                Id = a.AuditId.ToString(),
                SuiteName = a.SuiteName,
                ExecutedAt = a.ExecutedAt.ToString("yyyy-MM-dd HH:mm:ss"),
                Status = a.SuiteExecutionStatus ?? "",
                TotalCases = a.TotalTestCases,
                PassingCases = a.SuccessfulTestCases,
                DurationMs = a.DurationSeconds * 1000
            })];
    }
}
