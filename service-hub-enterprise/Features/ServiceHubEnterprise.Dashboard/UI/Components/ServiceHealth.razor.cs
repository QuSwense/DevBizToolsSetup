using Microsoft.AspNetCore.Components;

namespace ServiceHubEnterprise.Dashboard.UI.Components;

/// <summary>
/// Code-behind for the ServiceHealth component.
/// </summary>
public partial class ServiceHealth
{
    /// <summary>
    /// Gets or sets the card title.
    /// </summary>
    [Parameter] public string Title { get; set; } = "Service Health";

    /// <summary>
    /// Gets or sets the list of services with their health status.
    /// Expected status values: "ok" or "down".
    /// </summary>
    [Parameter]
    public IReadOnlyList<HealthServiceItem> Services { get; set; } = Array.Empty<HealthServiceItem>();

    private int TotalCount => Services.Count;
    private int OperationalCount => Services.Count(s => s.Status == "ok");
    private int DownCount => Services.Count(s => s.Status == "down");
    private int OperationalPct => TotalCount > 0 ? OperationalCount * 100 / TotalCount : 0;
    private int DownPct => TotalCount > 0 ? DownCount * 100 / TotalCount : 0;

    /// <summary>
    /// Represents a single service with a health status.
    /// </summary>
    public record HealthServiceItem(string Name, string Status);
}
