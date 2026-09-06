namespace OrbitHub.Dashboard.Application.DTOs;

/// <summary>
/// Point-in-time snapshot of every data set rendered on the dashboard,
/// assembled in parallel by the dashboard orchestration service.
/// </summary>
public sealed class DashboardSnapshotDto
{
    /// <summary>Aggregate dashboard metrics.</summary>
    public DashboardMetricsDto Metrics { get; set; } = new();

    /// <summary>Monitored service health entries.</summary>
    public IReadOnlyList<ServiceHealthDto> HealthServices { get; set; } = [];

    /// <summary>Test suite summaries.</summary>
    public IReadOnlyList<TestSuiteDto> TestSuites { get; set; } = [];

    /// <summary>Recent activity log entries.</summary>
    public IReadOnlyList<RecentActivityDto> RecentActivities { get; set; } = [];

    /// <summary>Request files (e.g., SOAP envelopes).</summary>
    public IReadOnlyList<RequestFileDto> RequestFiles { get; set; } = [];

    /// <summary>WSDL sync records.</summary>
    public IReadOnlyList<WsdlRecordDto> WsdlRecords { get; set; } = [];

    /// <summary>Application users.</summary>
    public IReadOnlyList<UserDto> Users { get; set; } = [];

    /// <summary>Currently signed-in user, or null when not resolvable.</summary>
    public UserDto? CurrentUser { get; set; }

    /// <summary>REST applications.</summary>
    public IReadOnlyList<RestAppDto> RestApps { get; set; } = [];

    /// <summary>SOAP applications.</summary>
    public IReadOnlyList<SoapAppDto> SoapApps { get; set; } = [];

    /// <summary>REST request files.</summary>
    public IReadOnlyList<RequestFileDto> RestRequestFiles { get; set; } = [];

    /// <summary>Timestamped user activity log.</summary>
    public IReadOnlyList<UserActivityDto> UserActivities { get; set; } = [];

    /// <summary>Request-file execution history (REST and SOAP).</summary>
    public IReadOnlyList<RequestExecutionDto> RequestExecutions { get; set; } = [];

    /// <summary>Historical runs of the test suites.</summary>
    public IReadOnlyList<TestSuiteHistoryDto> TestSuiteHistory { get; set; } = [];

    /// <summary>Time-series service health samples.</summary>
    public IReadOnlyList<ServiceUptimeDto> ServiceUptime { get; set; } = [];
}
