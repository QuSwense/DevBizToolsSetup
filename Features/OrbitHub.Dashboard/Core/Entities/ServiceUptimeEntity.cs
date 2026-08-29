namespace OrbitHub.Dashboard.Core.Entities;

/// <summary>
/// Represents a time-series health sample for a monitored service.
/// </summary>
public sealed class ServiceUptimeEntity
{
    public string Id { get; set; } = string.Empty;
    public string ServiceName { get; set; } = string.Empty;
    public string Timestamp { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
}
