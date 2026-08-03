using ServiceHubEnterprise.Dashboard.Core.Enums;

namespace ServiceHubEnterprise.Dashboard.Core.Entities;

/// <summary>
/// Represents a monitored service with its current health status.
/// </summary>
public sealed class ServiceHealthEntity
{
    public string Name { get; set; } = string.Empty;
    public ServiceStatus Status { get; set; }
}
