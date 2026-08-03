namespace ServiceHubEnterprise.Dashboard.Application.DTOs;

/// <summary>
/// Data transfer object for a time-series health sample of a monitored service.
/// </summary>
public sealed class ServiceUptimeDto
{
    public string Id { get; set; } = string.Empty;
    public string ServiceName { get; set; } = string.Empty;
    public string Timestamp { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
}
