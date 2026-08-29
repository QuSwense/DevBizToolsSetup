using Microsoft.AspNetCore.Components;

namespace OrbitHub.Ui.Components;

/// <summary>
/// Code-behind for the TimelineStrip component.
/// A horizontal, proportionally segmented status bar (e.g., uptime ok/degraded/down).
/// </summary>
public partial class TimelineStrip
{
    /// <summary>
    /// Represents a single colored segment of the timeline.
    /// </summary>
    public record Segment(double Width, string Color, string? Tooltip = null);

    /// <summary>
    /// Gets or sets the ordered list of segments; widths should sum to ~100.
    /// </summary>
    [Parameter]
    public IReadOnlyList<Segment> Segments { get; set; } = Array.Empty<Segment>();
}
