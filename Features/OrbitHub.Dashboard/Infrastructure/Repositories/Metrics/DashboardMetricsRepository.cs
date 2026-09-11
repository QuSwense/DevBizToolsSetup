using Microsoft.Extensions.DependencyInjection;
using OrbitHub.Dashboard.Core.Entities;
using OrbitHub.Dashboard.Core.Interfaces.Metrics;
using OrbitHub.Data.TestManagement.Views;

namespace OrbitHub.Dashboard.Infrastructure.Repositories.Metrics;

/// <summary>
/// Reads the aggregate dashboard KPI metrics through the generated OrbitHub.Data view repositories.
/// Counts without a backing column return zero.
/// </summary>
internal sealed class DashboardMetricsRepository(IServiceProvider serviceProvider) : IDashboardMetricsRepository
{
    private readonly IServiceProvider _serviceProvider = serviceProvider;

    /// <inheritdoc />
    public async Task<DashboardMetricsEntity> GetMetricsAsync()
    {
        using var scope = _serviceProvider.CreateScope();
        var applicationsView = scope.ServiceProvider.GetRequiredService<LatestServiceApplicationWithAuthViewRepository>();
        var testSuitesView = scope.ServiceProvider.GetRequiredService<ServiceTestSuiteWithDetailsViewRepository>();

        var applications = ViewRepositoryResult.OrThrow(await applicationsView.GetAllAsync());
        var testSuites = ViewRepositoryResult.OrThrow(await testSuitesView.GetAllAsync());

        var soapApps = applications.Where(a => a.ServiceType.Equals("SOAP", StringComparison.OrdinalIgnoreCase)).ToList();
        var restApps = applications.Where(a => a.ServiceType.Equals("REST", StringComparison.OrdinalIgnoreCase)).ToList();

        return new DashboardMetricsEntity
        {
            SoapAppCount = soapApps.Count,
            SoapAppsEnabled = soapApps.Count(a => a.IsActive == true),
            RestAppCount = restApps.Count,
            RestAppsEnabled = restApps.Count(a => a.IsActive == true),
            TestSuiteCount = testSuites.Count,
            TotalCases = testSuites.Sum(s => s.TestCaseCount),
            PassingCases = 0 // no case-level pass/fail tracking in the schema yet
        };
    }
}
