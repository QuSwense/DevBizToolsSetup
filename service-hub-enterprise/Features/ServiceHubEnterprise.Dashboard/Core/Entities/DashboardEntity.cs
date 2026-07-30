using ServiceHubEnterprise.Dashboard.Core.Enums;

namespace ServiceHubEnterprise.Dashboard.Core.Entities;

/// <summary>
/// Represents a monitored service with its current health status.
/// </summary>
public sealed class ServiceHealthEntity
{
    public string Name { get; set; } = string.Empty;
    public ServiceStatus Status { get; set; }
}

/// <summary>
/// Represents a test suite tracked on the dashboard.
/// </summary>
public sealed class TestSuiteEntity
{
    public string Name { get; set; } = string.Empty;
    public int TotalCases { get; set; }
    public int PassingCases { get; set; }
    public int TotalFiles { get; set; }
}
