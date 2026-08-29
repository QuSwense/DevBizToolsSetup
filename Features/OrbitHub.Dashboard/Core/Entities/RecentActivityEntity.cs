namespace OrbitHub.Dashboard.Core.Entities;

/// <summary>
/// Represents a recent activity log entry.
/// </summary>
public sealed class RecentActivityEntity
{
    public string User { get; set; } = string.Empty;
    public string Action { get; set; } = string.Empty;
    public string TimeAgo { get; set; } = string.Empty;
}
