using OrbitHub.Dashboard.Application.DTOs;

namespace OrbitHub.Dashboard.Application.Services.Users;

/// <summary>
/// Provides the platform users and their activity feeds surfaced on the dashboard.
/// </summary>
public interface IDashboardUsersService
{
    /// <summary>
    /// Retrieves all application users.
    /// </summary>
    Task<IReadOnlyList<UserDto>> GetUsersAsync();

    /// <summary>
    /// Retrieves the currently signed-in user, or null when not resolvable.
    /// </summary>
    Task<UserDto?> GetCurrentUserAsync();

    /// <summary>
    /// Retrieves the timestamped user activity log.
    /// </summary>
    Task<IReadOnlyList<UserActivityDto>> GetUserActivitiesAsync();

    /// <summary>
    /// Retrieves the recent activity log entries.
    /// </summary>
    /// <param name="maxEntries">Maximum number of entries to return.</param>
    Task<IReadOnlyList<RecentActivityDto>> GetRecentActivityAsync(int maxEntries = 10);
}
