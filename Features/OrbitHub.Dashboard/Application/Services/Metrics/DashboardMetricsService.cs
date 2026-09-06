using OrbitHub.Dashboard.Application.DTOs;
using OrbitHub.Dashboard.Core.Interfaces.Metrics;

namespace OrbitHub.Dashboard.Application.Services.Metrics;

/// <summary>
/// Provides the aggregate dashboard metrics by reading from the metrics repository.
/// </summary>
internal sealed class DashboardMetricsService(IDashboardMetricsRepository repository) : IDashboardMetricsService
{
    private readonly IDashboardMetricsRepository _repository = repository;

    /// <inheritdoc />
    public async Task<DashboardMetricsDto> GetMetricsAsync()
    {
        var entity = await _repository.GetMetricsAsync();

        return new DashboardMetricsDto
        {
            RestAppCount = entity.RestAppCount,
            RestAppsEnabled = entity.RestAppsEnabled,
            SoapAppCount = entity.SoapAppCount,
            SoapAppsEnabled = entity.SoapAppsEnabled,
            TestSuiteCount = entity.TestSuiteCount,
            PassingCases = entity.PassingCases,
            TotalCases = entity.TotalCases
        };
    }
}
