using OrbitHub.Dashboard.Application.DTOs;

namespace OrbitHub.Dashboard.Application.Services;

/// <summary>
/// Defines the contract for dashboard data operations.
/// </summary>
public interface IDashboardService
{
    /// <summary>
    /// Retrieves the aggregate metrics for the dashboard overview.
    /// </summary>
    Task<DashboardMetricsDto> GetMetricsAsync();

    /// <summary>
    /// Retrieves all service health entries.
    /// </summary>
    Task<IReadOnlyList<ServiceHealthDto>> GetServiceHealthAsync();

    /// <summary>
    /// Retrieves all test suite summaries.
    /// </summary>
    Task<IReadOnlyList<TestSuiteDto>> GetTestSuitesAsync();

    /// <summary>
    /// Retrieves the recent activity log entries.
    /// </summary>
    /// <param name="maxEntries">Maximum number of entries to return.</param>
    Task<IReadOnlyList<RecentActivityDto>> GetRecentActivityAsync(int maxEntries = 10);

    /// <summary>
    /// Retrieves all request files (e.g., SOAP envelopes).
    /// </summary>
    Task<IReadOnlyList<RequestFileDto>> GetRequestFilesAsync();

    /// <summary>
    /// Retrieves all WSDL sync records.
    /// </summary>
    Task<IReadOnlyList<WsdlRecordDto>> GetWsdlRecordsAsync();

    /// <summary>
    /// Retrieves all application users.
    /// </summary>
    Task<IReadOnlyList<UserDto>> GetUsersAsync();

    /// <summary>
    /// Retrieves the currently signed-in user, or null when not resolvable.
    /// </summary>
    Task<UserDto?> GetCurrentUserAsync();

    /// <summary>
    /// Retrieves all REST applications.
    /// </summary>
    Task<IReadOnlyList<RestAppDto>> GetRestAppsAsync();

    /// <summary>
    /// Retrieves all SOAP applications.
    /// </summary>
    Task<IReadOnlyList<SoapAppDto>> GetSoapAppsAsync();

    /// <summary>
    /// Retrieves all REST request files.
    /// </summary>
    Task<IReadOnlyList<RequestFileDto>> GetRestRequestFilesAsync();

    /// <summary>
    /// Retrieves the timestamped user activity log.
    /// </summary>
    Task<IReadOnlyList<UserActivityDto>> GetUserActivitiesAsync();

    /// <summary>
    /// Retrieves the request-file execution history (REST and SOAP).
    /// </summary>
    Task<IReadOnlyList<RequestExecutionDto>> GetRequestExecutionsAsync();

    /// <summary>
    /// Retrieves the historical runs of the test suites.
    /// </summary>
    Task<IReadOnlyList<TestSuiteHistoryDto>> GetTestSuiteHistoryAsync();

    /// <summary>
    /// Retrieves the time-series service health samples.
    /// </summary>
    Task<IReadOnlyList<ServiceUptimeDto>> GetServiceUptimeAsync();
}
