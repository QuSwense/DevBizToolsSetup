using OrbitHub.Dashboard.Core.Entities;

namespace OrbitHub.Dashboard.Core.Interfaces.Users;

/// <summary>
/// Reads the platform users and their activity feeds surfaced on the dashboard.
/// </summary>
public interface IDashboardUsersRepository
{
    /// <summary>
    /// Retrieves all application users.
    /// </summary>
    Task<IReadOnlyList<UserEntity>> GetUsersAsync();

    /// <summary>
    /// Retrieves the currently signed-in user, or null when not resolvable.
    /// </summary>
    Task<UserEntity?> GetCurrentUserAsync();

    /// <summary>
    /// Retrieves the timestamped user activity log.
    /// </summary>
    Task<IReadOnlyList<UserActivityEntity>> GetUserActivitiesAsync();

    /// <summary>
    /// Retrieves the recent activity log entries.
    /// </summary>
    Task<IReadOnlyList<RecentActivityEntity>> GetRecentActivityAsync();
}
