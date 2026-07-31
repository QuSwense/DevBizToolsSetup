namespace ServiceHubEnterprise.Dashboard.Core.Entities;

/// <summary>
/// Represents a timestamped user activity event.
/// </summary>
public sealed class UserActivityEntity
{
    public string Id { get; set; } = string.Empty;
    public string UserName { get; set; } = string.Empty;
    public string Action { get; set; } = string.Empty;
    public string Timestamp { get; set; } = string.Empty;
}
