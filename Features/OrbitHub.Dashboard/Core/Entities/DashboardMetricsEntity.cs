namespace OrbitHub.Dashboard.Core.Entities;

/// <summary>
/// Represents the aggregate metrics for the dashboard overview.
/// </summary>
public sealed class DashboardMetricsEntity
{
    public int RestAppCount { get; set; }
    public int RestAppsEnabled { get; set; }
    public int SoapAppCount { get; set; }
    public int SoapAppsEnabled { get; set; }
    public int TestSuiteCount { get; set; }
    public int PassingCases { get; set; }
    public int TotalCases { get; set; }
}
