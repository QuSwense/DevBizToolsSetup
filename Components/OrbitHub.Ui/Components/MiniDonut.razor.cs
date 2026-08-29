using Microsoft.AspNetCore.Components;

namespace OrbitHub.Ui.Components;

/// <summary>
/// Code-behind for the MiniDonut component.
/// A compact SVG donut showing a value as a percentage of a total.
/// </summary>
public partial class MiniDonut
{
    /// <summary>
    /// Gets or sets the numerator value.
    /// </summary>
    [Parameter] public int Value { get; set; }

    /// <summary>
    /// Gets or sets the denominator total.
    /// </summary>
    [Parameter] public int Total { get; set; }

    /// <summary>
    /// Gets or sets the sub-label shown under the percentage.
    /// </summary>
    [Parameter] public string Label { get; set; }

    /// <summary>
    /// Gets or sets the color of the value arc (CSS color).
    /// </summary>
    [Parameter] public string ValueColor { get; set; } = "var(--sh-success)";

    /// <summary>
    /// Gets or sets the rendered size in pixels.
    /// </summary>
    [Parameter] public int Size { get; set; } = 100;

    private int Pct => Total > 0 ? Value * 100 / Total : 0;
}
