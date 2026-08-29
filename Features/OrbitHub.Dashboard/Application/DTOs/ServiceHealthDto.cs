namespace OrbitHub.Dashboard.Application.DTOs;

/// <summary>
/// Data transfer object for a monitored service's health status.
/// </summary>
public sealed class ServiceHealthDto
{
    public string Name { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
}
