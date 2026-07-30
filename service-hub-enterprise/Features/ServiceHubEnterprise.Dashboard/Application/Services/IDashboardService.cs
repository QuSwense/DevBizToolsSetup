using ServiceHubEnterprise.Dashboard.Application.DTOs;

namespace ServiceHubEnterprise.Dashboard.Application.Services;

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
    /// Retrieves the recent activity log entries.
    /// </summary>
    /// <param name="maxEntries">Maximum number of entries to return.</param>
    Task<IReadOnlyList<RecentActivityDto>> GetRecentActivityAsync(int maxEntries = 10);
}
