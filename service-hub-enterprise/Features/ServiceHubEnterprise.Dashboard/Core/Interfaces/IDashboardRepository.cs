using ServiceHubEnterprise.Dashboard.Core.Entities;

namespace ServiceHubEnterprise.Dashboard.Core.Interfaces;

/// <summary>
/// Defines the contract for dashboard data persistence.
/// </summary>
public interface IDashboardRepository
{
    /// <summary>
    /// Retrieves the aggregate metrics for the dashboard overview.
    /// </summary>
    Task<DashboardMetricsEntity> GetMetricsAsync();

    /// <summary>
    /// Retrieves all service health entities.
    /// </summary>
    Task<IReadOnlyList<ServiceHealthEntity>> GetServiceHealthAsync();

    /// <summary>
    /// Retrieves all test suite entities.
    /// </summary>
    Task<IReadOnlyList<TestSuiteEntity>> GetTestSuitesAsync();

    /// <summary>
    /// Retrieves the recent activity log entries.
    /// </summary>
    Task<IReadOnlyList<RecentActivityEntity>> GetRecentActivityAsync();

    /// <summary>
    /// Retrieves all request files (e.g., SOAP envelopes).
    /// </summary>
    Task<IReadOnlyList<RequestFileEntity>> GetRequestFilesAsync();

    /// <summary>
    /// Retrieves all WSDL sync records.
    /// </summary>
    Task<IReadOnlyList<WsdlRecordEntity>> GetWsdlRecordsAsync();

    /// <summary>
    /// Retrieves all application users.
    /// </summary>
    Task<IReadOnlyList<UserEntity>> GetUsersAsync();

    /// <summary>
    /// Retrieves the currently signed-in user, or null when not resolvable.
    /// </summary>
    Task<UserEntity?> GetCurrentUserAsync();

    /// <summary>
    /// Retrieves all REST applications.
    /// </summary>
    Task<IReadOnlyList<RestAppEntity>> GetRestAppsAsync();

    /// <summary>
    /// Retrieves all SOAP applications.
    /// </summary>
    Task<IReadOnlyList<SoapAppEntity>> GetSoapAppsAsync();

    /// <summary>
    /// Retrieves all REST request files.
    /// </summary>
    Task<IReadOnlyList<RequestFileEntity>> GetRestRequestFilesAsync();

    /// <summary>
    /// Retrieves the timestamped user activity log.
    /// </summary>
    Task<IReadOnlyList<UserActivityEntity>> GetUserActivitiesAsync();

    /// <summary>
    /// Retrieves the request-file execution history (REST and SOAP).
    /// </summary>
    Task<IReadOnlyList<RequestExecutionEntity>> GetRequestExecutionsAsync();

    /// <summary>
    /// Retrieves the historical runs of the test suites.
    /// </summary>
    Task<IReadOnlyList<TestSuiteHistoryEntity>> GetTestSuiteHistoryAsync();

    /// <summary>
    /// Retrieves the time-series service health samples.
    /// </summary>
    Task<IReadOnlyList<ServiceUptimeEntity>> GetServiceUptimeAsync();
}
