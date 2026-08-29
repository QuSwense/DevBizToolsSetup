using Microsoft.AspNetCore.Components;
using Microsoft.JSInterop;
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

    [Inject]
    private IJSRuntime Js { get; set; } = null!;

    private DashboardViewModel _viewModel = new();
    private bool _isLoading = true;
    private string? _errorMessage;

    private readonly IReadOnlyList<KpiMetric> _kpiMetrics =
    [
        new("Total Registered Applications", "36", "+4 this month"),
        new("Total Active Users Today / Week / Month", "1,284 / 2,340 / 8,191", "+15% vs last month"),
        new("Total Departments Using the Tool", "18", "+5 new departments"),
        new("Requests Processed Today / Week / Month", "1,240 / 2,500 / 13,200", "95% success rate"),
        new("Success Rate", "95.8%", "Stable execution quality"),
        new("Number of Test Assets Managed", "1,284", "Across SOAP and REST"),
        new("XML Files", "342", "Updated this month"),
        new("Templates", "88", "21 ready for deployment"),
        new("WSDL Versions", "27", "3 new this month")
    ];

    private readonly IReadOnlyList<ApplicationUsage> _topApplications =
    [
        new("Application A", 240, 42),
        new("Application B", 185, 32),
        new("Application C", 115, 19),
        new("Application D", 55, 7)
    ];

    private readonly IReadOnlyList<GrowthMetric> _growthMetrics =
    [
        new("New Users Added", "146"),
        new("New Applications Registered", "12"),
        new("New XML Templates Created", "28"),
        new("New WSDL Versions Published", "4")
    ];

    private readonly IReadOnlyList<ServiceHealthMetric> _serviceHealth =
    [
        new("Platform Availability", "Healthy", "healthy"),
        new("Database Connectivity", "Healthy", "healthy"),
        new("Authentication Service", "Healthy", "healthy"),
        new("SOAP Execution Engine", "Healthy", "healthy")
    ];

    private readonly IReadOnlyList<string> _insights =
    [
        "15% growth in active users this month.",
        "5 new departments onboarded.",
        "2,500 requests processed this week.",
        "95% of executions completed successfully.",
        "Top consuming application: Claims Service."
    ];

    private readonly IReadOnlyList<ActivityItem> _recentActivities =
    [
        new("08:42 AM", "Claims Service processed 220 requests successfully."),
        new("08:10 AM", "New XML template published for Billing API."),
        new("Yesterday", "3 departments were onboarded to the platform."),
        new("2 days ago", "WSDL version 4.8 was approved for release.")
    ];

    private readonly IReadOnlyList<string> _recentAccessLinks =
    [
        "Claims Service",
        "Billing Gateway",
        "Customer Compliance",
        "REST Templates",
        "SOAP Execution History"
    ];

    // Per-card expand/collapse state, persisted to localStorage via JS interop.
    private readonly Dictionary<string, bool> _cardCollapsed = new();
    private IJSObjectReference? _collapseModule;

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

    /// <inheritdoc />
    protected override async Task OnAfterRenderAsync(bool firstRender)
    {
        if (!firstRender)
        {
            return;
        }

        // Hydrate the persisted per-card collapse state once the client circuit is live.
        try
        {
            _collapseModule = await Js.InvokeAsync<IJSObjectReference>(
                "import", "./_content/ServiceHubEnterprise.Ui/js/collapse.js");
            var saved = await _collapseModule.InvokeAsync<Dictionary<string, bool>>("getAll");
            if (saved is not null)
            {
                foreach (var (key, collapsed) in saved)
                {
                    _cardCollapsed[key] = collapsed;
                }
            }
        }
        catch
        {
            // Interop unavailable (e.g. prerender) — fall back to expanded defaults.
        }

        StateHasChanged();
    }

    private bool IsCollapsed(string key) =>
        _cardCollapsed.TryGetValue(key, out var collapsed) && collapsed;

    private async Task ToggleCard(string key, bool collapsed)
    {
        _cardCollapsed[key] = collapsed;
        if (_collapseModule is not null)
        {
            await _collapseModule.InvokeVoidAsync("set", key, collapsed);
        }
    }

    private Task OnUsersToggle(bool collapsed) => ToggleCard(CardKey.Users, collapsed);
    private Task OnRestToggle(bool collapsed) => ToggleCard(CardKey.Rest, collapsed);
    private Task OnSoapToggle(bool collapsed) => ToggleCard(CardKey.Soap, collapsed);
    private Task OnTestSuitesToggle(bool collapsed) => ToggleCard(CardKey.TestSuites, collapsed);
    private Task OnServiceHealthToggle(bool collapsed) => ToggleCard(CardKey.ServiceHealth, collapsed);
    private Task OnRecentActivityToggle(bool collapsed) => ToggleCard(CardKey.RecentActivity, collapsed);

    /// <inheritdoc />
    public async ValueTask DisposeAsync()
    {
        if (_collapseModule is not null)
        {
            await _collapseModule.DisposeAsync();
        }
    }

    private static class CardKey
    {
        public const string Users = "users";
        public const string Rest = "rest";
        public const string Soap = "soap";
        public const string TestSuites = "test-suites";
        public const string ServiceHealth = "service-health";
        public const string RecentActivity = "recent-activity";
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

    private sealed record KpiMetric(string Label, string Value, string Detail);

    private sealed record ApplicationUsage(string Name, int Executions, int Contribution);

    private sealed record GrowthMetric(string Label, string Value);

    private sealed record ServiceHealthMetric(string Name, string Status, string StatusClass);

    private sealed record ActivityItem(string Time, string Message);
}
