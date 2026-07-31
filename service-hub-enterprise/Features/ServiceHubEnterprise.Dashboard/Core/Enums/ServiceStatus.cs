using System.Text.Json.Serialization;

namespace ServiceHubEnterprise.Dashboard.Core.Enums;

/// <summary>
/// Represents the operational status of a service tracked on the dashboard.
/// </summary>
[JsonConverter(typeof(JsonStringEnumConverter))]
public enum ServiceStatus
{
    Unknown,
    Ok,
    Degraded,
    Down
}
