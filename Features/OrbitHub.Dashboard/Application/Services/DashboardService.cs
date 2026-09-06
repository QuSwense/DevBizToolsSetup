using OrbitHub.Dashboard.Application.DTOs;
using OrbitHub.Dashboard.Application.Services.Applications;
using OrbitHub.Dashboard.Application.Services.Assets;
using OrbitHub.Dashboard.Application.Services.Executions;
using OrbitHub.Dashboard.Application.Services.Health;
using OrbitHub.Dashboard.Application.Services.Metrics;
using OrbitHub.Dashboard.Application.Services.TestSuites;
using OrbitHub.Dashboard.Application.Services.Users;

namespace OrbitHub.Dashboard.Application.Services;

/// <summary>
/// Orchestrates the grouped dashboard services, fanning out every section call in
/// parallel and assembling the results into a single <see cref="DashboardSnapshotDto"/>.
/// </summary>
internal sealed class DashboardService(
    IDashboardMetricsService metricsService,
    IDashboardApplicationsService applicationsService,
    IDashboardAssetsService assetsService,
    IDashboardUsersService usersService,
    IDashboardTestSuitesService testSuitesService,
    IDashboardExecutionsService executionsService,
    IDashboardHealthService healthService) : IDashboardService
{
    /// <inheritdoc />
    public async Task<DashboardSnapshotDto> GetDashboardAsync()
    {
        // Fire every group call concurrently; each repository call opens its own DI scope.
        var metricsTask = metricsService.GetMetricsAsync();
        var healthTask = healthService.GetServiceHealthAsync();
        var uptimeTask = healthService.GetServiceUptimeAsync();
        var suitesTask = testSuitesService.GetTestSuitesAsync();
        var suiteHistoryTask = testSuitesService.GetTestSuiteHistoryAsync();
        var requestFilesTask = assetsService.GetRequestFilesAsync();
        var restRequestFilesTask = assetsService.GetRestRequestFilesAsync();
        var wsdlTask = assetsService.GetWsdlRecordsAsync();
        var usersTask = usersService.GetUsersAsync();
        var currentUserTask = usersService.GetCurrentUserAsync();
        var recentActivityTask = usersService.GetRecentActivityAsync();
        var userActivitiesTask = usersService.GetUserActivitiesAsync();
        var restAppsTask = applicationsService.GetRestAppsAsync();
        var soapAppsTask = applicationsService.GetSoapAppsAsync();
        var executionsTask = executionsService.GetRequestExecutionsAsync();

        await Task.WhenAll(
            metricsTask, healthTask, uptimeTask, suitesTask, suiteHistoryTask,
            requestFilesTask, restRequestFilesTask, wsdlTask,
            usersTask, currentUserTask, recentActivityTask, userActivitiesTask,
            restAppsTask, soapAppsTask, executionsTask);

        return new DashboardSnapshotDto
        {
            Metrics = metricsTask.Result,
            HealthServices = healthTask.Result,
            ServiceUptime = uptimeTask.Result,
            TestSuites = suitesTask.Result,
            TestSuiteHistory = suiteHistoryTask.Result,
            RequestFiles = requestFilesTask.Result,
            RestRequestFiles = restRequestFilesTask.Result,
            WsdlRecords = wsdlTask.Result,
            Users = usersTask.Result,
            CurrentUser = currentUserTask.Result,
            RecentActivities = recentActivityTask.Result,
            UserActivities = userActivitiesTask.Result,
            RestApps = restAppsTask.Result,
            SoapApps = soapAppsTask.Result,
            RequestExecutions = executionsTask.Result
        };
    }
}
