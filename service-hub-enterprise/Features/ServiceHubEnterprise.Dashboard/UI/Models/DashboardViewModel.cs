namespace ServiceHubEnterprise.Dashboard.UI.Models;

/// <summary>
/// View model for the main dashboard page combining all UI data.
/// </summary>
public sealed class DashboardViewModel
{
    public int RestAppCount { get; set; }
    public int SoapAppCount { get; set; }
    public int TestSuiteCount { get; set; }
    public int TotalCases { get; set; }
    public int PassingCases { get; set; }
    public IReadOnlyList<ServiceHealthViewModel> HealthServices { get; set; } = Array.Empty<ServiceHealthViewModel>();
    public IReadOnlyList<TestSuiteViewModel> TestSuites { get; set; } = Array.Empty<TestSuiteViewModel>();
    public IReadOnlyList<ActivityViewModel> RecentActivity { get; set; } = Array.Empty<ActivityViewModel>();
}

/// <summary>
/// View model for a monitored service's health status.
/// </summary>
public sealed class ServiceHealthViewModel
{
    public string Name { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
}

/// <summary>
/// View model for a test suite summary.
/// </summary>
public sealed class TestSuiteViewModel
{
    public string Name { get; set; } = string.Empty;
    public int Cases { get; set; }
    public int Files { get; set; }
}

/// <summary>
/// View model for a recent activity log entry.
/// </summary>
public sealed class ActivityViewModel
{
    public string User { get; set; } = string.Empty;
    public string Action { get; set; } = string.Empty;
    public string Time { get; set; } = string.Empty;
}
