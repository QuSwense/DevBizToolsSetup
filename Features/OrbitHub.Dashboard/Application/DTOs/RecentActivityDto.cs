namespace OrbitHub.Dashboard.Application.DTOs;

/// <summary>
/// Data transfer object for a recent activity log entry.
/// </summary>
public sealed class RecentActivityDto
{
    /// <summary>The user who performed the action.</summary>
    public string User { get; set; } = string.Empty;

    /// <summary>Description of the action performed.</summary>
    public string Action { get; set; } = string.Empty;

    /// <summary>Relative time description (e.g., "2 hours ago").</summary>
    public string TimeAgo { get; set; } = string.Empty;
}
