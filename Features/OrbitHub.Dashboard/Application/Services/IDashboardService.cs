using OrbitHub.Dashboard.Application.DTOs;

namespace OrbitHub.Dashboard.Application.Services;

/// <summary>
/// Orchestrates the grouped dashboard services to assemble the complete dashboard snapshot.
/// Consumers needing a single section should inject the matching group service instead
/// (e.g., <c>IDashboardMetricsService</c>, <c>IDashboardUsersService</c>).
/// </summary>
public interface IDashboardService
{
    /// <summary>
    /// Loads every dashboard data set in parallel and returns the assembled snapshot.
    /// </summary>
    Task<DashboardSnapshotDto> GetDashboardAsync();
}
