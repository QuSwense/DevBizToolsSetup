using Microsoft.AspNetCore.Components;

namespace OrbitHub.Dashboard.UI.Components;

/// <summary>
/// Code-behind for the QuickActions component.
/// </summary>
public partial class QuickActions
{
    /// <summary>
    /// Gets or sets the card title.
    /// </summary>
    [Parameter] public string Title { get; set; } = "Quick Actions";

    /// <summary>
    /// Gets or sets the list of quick action links.
    /// </summary>
    [Parameter]
    public IReadOnlyList<QuickActionItem> Actions { get; set; } = Array.Empty<QuickActionItem>();

    /// <summary>
    /// Represents a single quick action link.
    /// </summary>
    public record QuickActionItem(string Label, string Href, string? Icon = null);
}
