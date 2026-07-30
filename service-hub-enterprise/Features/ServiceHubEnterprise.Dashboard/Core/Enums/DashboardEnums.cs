namespace ServiceHubEnterprise.Dashboard.Core.Enums;

/// <summary>
/// Represents the operational status of a service tracked on the dashboard.
/// </summary>
public enum ServiceStatus
{
    Unknown,
    Ok,
    Degraded,
    Down
}

/// <summary>
/// Represents the type of a chart widget displayed on the dashboard.
/// </summary>
public enum ChartType
{
    Bar,
    Status,
    Line
}
