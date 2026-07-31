using Microsoft.AspNetCore.Components;

namespace ServiceHubEnterprise.Dashboard.UI.Components;

/// <summary>
/// Code-behind for the ChartWidgets component.
/// </summary>
public partial class ChartWidgets
{
    /// <summary>
    /// Gets or sets the collection of chart widgets to render.
    /// </summary>
    [Parameter]
    public IReadOnlyList<ChartWidget> Widgets { get; set; } = Array.Empty<ChartWidget>();

    private static double NormalizeValue(int value, IReadOnlyList<(string Label, int Value, string Color)> dataPoints)
    {
        var max = dataPoints.Count > 0 ? dataPoints.Max(dp => dp.Value) : 1;
        return max > 0 ? (double)value / max * 100 : 0;
    }

    /// <summary>
    /// Represents a chart widget with a title, type, and data points.
    /// </summary>
    public record ChartWidget(string Title, string Type, IReadOnlyList<(string Label, int Value, string Color)> DataPoints);
}
