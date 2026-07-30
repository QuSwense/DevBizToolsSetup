namespace ServiceHubEnterprise.Dashboard.Application.DTOs;

/// <summary>
/// Data transfer object for aggregate dashboard metrics.
/// </summary>
public sealed class DashboardMetricsDto
{
    /// <summary>Total number of REST applications.</summary>
    public int RestAppCount { get; set; }

    /// <summary>Number of REST applications currently enabled.</summary>
    public int RestAppsEnabled { get; set; }

    /// <summary>Total number of SOAP applications.</summary>
    public int SoapAppCount { get; set; }

    /// <summary>Number of SOAP applications currently enabled.</summary>
    public int SoapAppsEnabled { get; set; }

    /// <summary>Total number of test suites.</summary>
    public int TestSuiteCount { get; set; }

    /// <summary>Number of test cases that are passing.</summary>
    public int PassingCases { get; set; }

    /// <summary>Total number of test cases across all suites.</summary>
    public int TotalCases { get; set; }
}
