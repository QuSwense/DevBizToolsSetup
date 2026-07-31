using Microsoft.AspNetCore.Components;
using ServiceHubEnterprise.Dashboard.Application.Services;
using ServiceHubEnterprise.Dashboard.UI.Components;
using ServiceHubEnterprise.Dashboard.UI.Models;

namespace ServiceHubEnterprise.Dashboard.UI.Pages;

/// <summary>
/// Code-behind for the main Dashboard page.
/// Follows the clean architecture flow: Page → ViewModel → Service → DTO → Repository.
/// </summary>
public partial class Dashboard
{
    [Inject]
    private IDashboardService DashboardService { get; set; } = null!;

    private DashboardViewModel _viewModel = new();
    private bool _isLoading = true;
    private string? _errorMessage;

    /// <inheritdoc />
    protected override async Task OnInitializedAsync()
    {
        try
        {
            var metricsTask = DashboardService.GetMetricsAsync();
            var healthTask = DashboardService.GetServiceHealthAsync();
            var suitesTask = DashboardService.GetTestSuitesAsync();
            var requestFilesTask = DashboardService.GetRequestFilesAsync();
            var wsdlTask = DashboardService.GetWsdlRecordsAsync();
            var usersTask = DashboardService.GetUsersAsync();
            var restAppsTask = DashboardService.GetRestAppsAsync();
            var soapAppsTask = DashboardService.GetSoapAppsAsync();
            var restRequestFilesTask = DashboardService.GetRestRequestFilesAsync();
            var userActivitiesTask = DashboardService.GetUserActivitiesAsync();
            var requestExecutionsTask = DashboardService.GetRequestExecutionsAsync();
            var testSuiteHistoryTask = DashboardService.GetTestSuiteHistoryAsync();
            var serviceUptimeTask = DashboardService.GetServiceUptimeAsync();

            await Task.WhenAll(
                metricsTask, healthTask, suitesTask, requestFilesTask, wsdlTask, usersTask,
                restAppsTask, soapAppsTask, restRequestFilesTask, userActivitiesTask,
                requestExecutionsTask, testSuiteHistoryTask, serviceUptimeTask);

            _viewModel = new DashboardViewModel
            {
                Metrics = metricsTask.Result,
                HealthServices = healthTask.Result,
                TestSuites = suitesTask.Result,
                RequestFiles = requestFilesTask.Result,
                WsdlRecords = wsdlTask.Result,
                Users = usersTask.Result,
                RestApps = restAppsTask.Result,
                SoapApps = soapAppsTask.Result,
                RestRequestFiles = restRequestFilesTask.Result,
                UserActivities = userActivitiesTask.Result,
                RequestExecutions = requestExecutionsTask.Result,
                TestSuiteHistory = testSuiteHistoryTask.Result,
                ServiceUptime = serviceUptimeTask.Result
            };
        }
        catch (Exception ex)
        {
            _errorMessage = ex.Message;
        }
        finally
        {
            _isLoading = false;
        }
    }

    // ── ViewModel → Component parameter mappings ──────────────────────

    private IReadOnlyList<RecentActivity.ActivityEntry> BuildActivityLog()
    {
        return _viewModel.UserActivities
            .Select(a => new RecentActivity.ActivityEntry(
                a.UserName,
                a.Action,
                DateTime.TryParse(a.Timestamp, out var dt) ? dt : DateTime.MinValue))
            .ToList();
    }

    private IReadOnlyList<string> BuildUserNames()
    {
        return _viewModel.Users
            .Select(u => u.Name)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
    }

    private static readonly IReadOnlyList<QuickActions.QuickActionItem> QuickActionItems = new[]
    {
        new QuickActions.QuickActionItem("File Library", "/File/Library", "bi bi-file-earmark"),
        new QuickActions.QuickActionItem("Execute History", "/Rest/ExecuteHistory", "bi bi-clock-history")
    };
}
