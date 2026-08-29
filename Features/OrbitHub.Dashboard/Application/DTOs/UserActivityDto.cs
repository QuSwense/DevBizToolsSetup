namespace OrbitHub.Dashboard.Application.DTOs;

/// <summary>
/// Data transfer object for a timestamped user activity event.
/// </summary>
public sealed class UserActivityDto
{
    public string Id { get; set; } = string.Empty;
    public string UserName { get; set; } = string.Empty;
    public string Action { get; set; } = string.Empty;
    public string Timestamp { get; set; } = string.Empty;
}
