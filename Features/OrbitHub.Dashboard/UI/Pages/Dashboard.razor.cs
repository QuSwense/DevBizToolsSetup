using Microsoft.AspNetCore.Components;
using Microsoft.JSInterop;
using OrbitHub.Dashboard.Application.DTOs;
using OrbitHub.Dashboard.Application.Services;
using OrbitHub.Dashboard.UI.Components;
using OrbitHub.Dashboard.UI.Models;

namespace OrbitHub.Dashboard.UI.Pages;

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

    // Populated after the snapshot loads so each tile mirrors a DashboardMetricsDto
    // property returned by the metrics repository (no hardcoded placeholder data).
    private IReadOnlyList<KpiMetric> _kpiMetrics = [];

    // Populated after the snapshot loads. Where no backing DTO exists yet, the matching
    // Build method returns an empty list instead of fabricated placeholder data.
    private IReadOnlyList<ApplicationUsage> _topApplications = [];
    private IReadOnlyList<ServiceHealthMetric> _serviceHealth = [];
    private IReadOnlyList<ActivityItem> _recentActivities = [];
    private IReadOnlyList<string> _recentAccessLinks = [];

    // Per-card expand/collapse state, persisted to localStorage via JS interop.
    private readonly Dictionary<string, bool> _cardCollapsed = [];
    private IJSObjectReference? _collapseModule;

    /// <inheritdoc />
    protected override async Task OnInitializedAsync()
    {
        try
        {
            // Single orchestrated load; the service fans out to the grouped services in parallel.
            var snapshot = await DashboardService.GetDashboardAsync();

            _viewModel = new DashboardViewModel
            {
                Metrics = snapshot.Metrics,
                HealthServices = snapshot.HealthServices,
                TestSuites = snapshot.TestSuites,
                RecentActivities = snapshot.RecentActivities,
                RequestFiles = snapshot.RequestFiles,
                WsdlRecords = snapshot.WsdlRecords,
                Users = snapshot.Users,
                CurrentUser = snapshot.CurrentUser,
                RestApps = snapshot.RestApps,
                SoapApps = snapshot.SoapApps,
                RestRequestFiles = snapshot.RestRequestFiles,
                UserActivities = snapshot.UserActivities,
                RequestExecutions = snapshot.RequestExecutions,
                TestSuiteHistory = snapshot.TestSuiteHistory,
                ServiceUptime = snapshot.ServiceUptime
            };

            // Project the DTO metric properties onto the KPI tile list.
            _kpiMetrics = BuildKpiMetrics(snapshot.Metrics);

            // Populate the remaining dashboard sections from their snapshot sources.
            _topApplications = BuildTopApplications(snapshot.RequestExecutions);
            _serviceHealth = BuildServiceHealth(snapshot.HealthServices);
            _recentActivities = BuildRecentActivities(snapshot.RecentActivities);
            _recentAccessLinks = BuildRecentAccessLinks(snapshot.RequestExecutions);
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
                "import", "./_content/OrbitHub.Ui/js/collapse.js");
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

    /// <summary>
    /// Projects each <see cref="DashboardMetricsDto"/> property onto a KPI tile so the
    /// executive summary cards display repository metrics instead of placeholder data.
    /// </summary>
    private static IReadOnlyList<KpiMetric> BuildKpiMetrics(DashboardMetricsDto metrics)
    {
        int restDisabled = metrics.RestAppCount - metrics.RestAppsEnabled;
        int soapDisabled = metrics.SoapAppCount - metrics.SoapAppsEnabled;
        int failingCases = metrics.TotalCases - metrics.PassingCases;

        return
        [
            new KpiMetric("Total REST Applications", metrics.RestAppCount.ToString("N0"),
                $"{metrics.RestAppsEnabled} enabled · {restDisabled} disabled", "🌐"),
            new KpiMetric("REST Applications Enabled", metrics.RestAppsEnabled.ToString("N0"),
                $"of {metrics.RestAppCount} total", "✅"),
            new KpiMetric("Total SOAP Applications", metrics.SoapAppCount.ToString("N0"),
                $"{metrics.SoapAppsEnabled} enabled · {soapDisabled} disabled", "🧾"),
            new KpiMetric("SOAP Applications Enabled", metrics.SoapAppsEnabled.ToString("N0"),
                $"of {metrics.SoapAppCount} total", "✅"),
            new KpiMetric("Test Suites", metrics.TestSuiteCount.ToString("N0"),
                "across REST and SOAP", "🧪"),
            new KpiMetric("Passing Test Cases", metrics.PassingCases.ToString("N0"),
                $"{failingCases} failing", "✅"),
            new KpiMetric("Total Test Cases", metrics.TotalCases.ToString("N0"),
                "across all suites", "🔢")
        ];
    }

    /// <summary>
    /// Top applications by execution volume, derived from the request-execution history.
    /// </summary>
    private static IReadOnlyList<ApplicationUsage> BuildTopApplications(IReadOnlyList<RequestExecutionDto> executions)
    {
        var grouped = executions
            .Where(e => !string.IsNullOrWhiteSpace(e.AppName))
            .GroupBy(e => e.AppName, StringComparer.OrdinalIgnoreCase)
            .Select(g => new { App = g.Key, Count = g.Count() })
            .OrderByDescending(x => x.Count)
            .Take(4)
            .ToList();

        int total = grouped.Sum(x => x.Count);

        return [.. grouped
            .Select(x => new ApplicationUsage(
                x.App,
                x.Count,
                total == 0 ? 0 : (int)Math.Round(x.Count * 100d / total)))];
    }

    /// <summary>
    /// Service health snapshot populated from the monitored health services.
    /// </summary>
    private static IReadOnlyList<ServiceHealthMetric> BuildServiceHealth(IReadOnlyList<ServiceHealthDto> health)
    {
        return [.. health
            .Where(h => !string.IsNullOrWhiteSpace(h.Name))
            .Select(h => new ServiceHealthMetric(
                h.Name,
                FormatServiceStatus(h.Status),
                ServiceStatusClass(h.Status)))];
    }

    /// <summary>
    /// Chronological activity log surfaced from the recent-activity data.
    /// </summary>
    private static IReadOnlyList<ActivityItem> BuildRecentActivities(IReadOnlyList<RecentActivityDto> activities)
    {
        return [.. activities
            .Where(a => !string.IsNullOrWhiteSpace(a.Action))
            .Take(6)
            .Select(a => new ActivityItem(
                a.TimeAgo,
                string.IsNullOrWhiteSpace(a.User) ? a.Action : $"{a.User} — {a.Action}"))];
    }

    /// <summary>
    /// Quick links to the most recently exercised applications, derived from the execution
    /// history. Used as the recent-access proxy until a dedicated access log is tracked.
    /// </summary>
    private static IReadOnlyList<string> BuildRecentAccessLinks(IReadOnlyList<RequestExecutionDto> executions)
    {
        return [.. executions
            .Where(e => !string.IsNullOrWhiteSpace(e.AppName))
            .Select(e => e.AppName)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Take(5)];
    }

    private static string FormatServiceStatus(string status)
    {
        return status.ToLowerInvariant() switch
        {
            "ok" or "healthy" => "Healthy",
            "degraded" => "Degraded",
            "down" or "unavailable" => "Down",
            _ => string.IsNullOrWhiteSpace(status) ? "Unknown" : status
        };
    }

    private static string ServiceStatusClass(string status)
    {
        return status.ToLowerInvariant() switch
        {
            "ok" or "healthy" => "healthy",
            "degraded" => "degraded",
            "down" or "unavailable" => "down",
            _ => "unknown"
        };
    }

    private IReadOnlyList<RecentActivity.ActivityEntry> BuildActivityLog()
    {
        return [.. _viewModel.UserActivities
            .Select(a => new RecentActivity.ActivityEntry(
                a.UserName,
                a.Action,
                DateTime.TryParse(a.Timestamp, out var dt) ? dt : DateTime.MinValue))];
    }

    private IReadOnlyList<string> BuildUserNames()
    {
        return [.. _viewModel.Users
            .Select(u => u.Name)
            .Distinct(StringComparer.OrdinalIgnoreCase)];
    }

    private static readonly IReadOnlyList<QuickActions.QuickActionItem> QuickActionItems = new[]
    {
        new QuickActions.QuickActionItem("File Library", "/File/Library", "bi bi-file-earmark"),
        new QuickActions.QuickActionItem("Execute History", "/Rest/ExecuteHistory", "bi bi-clock-history")
    };

    private sealed record KpiMetric(string Label, string Value, string Detail, string Icon);

    private sealed record ApplicationUsage(string Name, int Executions, int Contribution);

    private sealed record GrowthMetric(string Label, string Value);

    private sealed record ServiceHealthMetric(string Name, string Status, string StatusClass);

    private sealed record ActivityItem(string Time, string Message);
}
