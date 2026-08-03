using ServiceHubEnterprise.Dashboard.Application.DTOs;

namespace ServiceHubEnterprise.Dashboard.UI.Models;

/// <summary>
/// View model for the main dashboard page, managing UI state
/// populated from the application service layer.
/// </summary>
public sealed class DashboardViewModel
{
    /// <summary>
    /// Gets or sets the aggregate dashboard metrics.
    /// </summary>
    public DashboardMetricsDto? Metrics { get; set; }

    /// <summary>
    /// Gets or sets the list of monitored service health entries.
    /// </summary>
    public IReadOnlyList<ServiceHealthDto> HealthServices { get; set; } = Array.Empty<ServiceHealthDto>();

    /// <summary>
    /// Gets or sets the list of test suite summaries.
    /// </summary>
    public IReadOnlyList<TestSuiteDto> TestSuites { get; set; } = Array.Empty<TestSuiteDto>();

    /// <summary>
    /// Gets or sets the list of recent activity log entries.
    /// </summary>
    public IReadOnlyList<RecentActivityDto> RecentActivities { get; set; } = Array.Empty<RecentActivityDto>();

    /// <summary>
    /// Gets or sets the list of request files (e.g., SOAP envelopes).
    /// </summary>
    public IReadOnlyList<RequestFileDto> RequestFiles { get; set; } = Array.Empty<RequestFileDto>();

    /// <summary>
    /// Gets or sets the list of WSDL sync records.
    /// </summary>
    public IReadOnlyList<WsdlRecordDto> WsdlRecords { get; set; } = Array.Empty<WsdlRecordDto>();

    /// <summary>
    /// Gets or sets the list of application users.
    /// </summary>
    public IReadOnlyList<UserDto> Users { get; set; } = Array.Empty<UserDto>();

    /// <summary>
    /// Gets or sets the currently signed-in user, or null when not resolvable.
    /// </summary>
    public UserDto? CurrentUser { get; set; }

    /// <summary>
    /// Gets or sets the list of REST applications.
    /// </summary>
    public IReadOnlyList<RestAppDto> RestApps { get; set; } = Array.Empty<RestAppDto>();

    /// <summary>
    /// Gets or sets the list of SOAP applications.
    /// </summary>
    public IReadOnlyList<SoapAppDto> SoapApps { get; set; } = Array.Empty<SoapAppDto>();

    /// <summary>
    /// Gets or sets the list of REST request files.
    /// </summary>
    public IReadOnlyList<RequestFileDto> RestRequestFiles { get; set; } = Array.Empty<RequestFileDto>();

    /// <summary>
    /// Gets or sets the timestamped user activity log.
    /// </summary>
    public IReadOnlyList<UserActivityDto> UserActivities { get; set; } = Array.Empty<UserActivityDto>();

    /// <summary>
    /// Gets or sets the request-file execution history (REST and SOAP).
    /// </summary>
    public IReadOnlyList<RequestExecutionDto> RequestExecutions { get; set; } = Array.Empty<RequestExecutionDto>();

    /// <summary>
    /// Gets or sets the historical runs of the test suites.
    /// </summary>
    public IReadOnlyList<TestSuiteHistoryDto> TestSuiteHistory { get; set; } = Array.Empty<TestSuiteHistoryDto>();

    /// <summary>
    /// Gets or sets the time-series service health samples.
    /// </summary>
    public IReadOnlyList<ServiceUptimeDto> ServiceUptime { get; set; } = Array.Empty<ServiceUptimeDto>();

    /// <summary>
    /// Gets whether the view model has been populated with data.
    /// </summary>
    public bool IsLoaded => Metrics is not null;
}
