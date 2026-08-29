using Microsoft.AspNetCore.Components;

namespace OrbitHub.Dashboard.UI.Components;

/// <summary>
/// Code-behind for the DashboardMetrics component.
/// </summary>
public partial class DashboardMetrics
{
    /// <summary>
    /// Gets or sets the collection of dashboard metrics to display.
    /// </summary>
    [Parameter]
    public IReadOnlyList<MetricItem> Metrics { get; set; } = Array.Empty<MetricItem>();

    /// <summary>
    /// Represents a single metric item displayed in the metrics row.
    /// </summary>
    public record MetricItem(string Label, string Value, string? Sub = null, string? Color = null, string? Icon = null);
}
