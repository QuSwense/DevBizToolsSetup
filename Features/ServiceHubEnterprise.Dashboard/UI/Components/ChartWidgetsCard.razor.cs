using Microsoft.AspNetCore.Components;

namespace ServiceHubEnterprise.Dashboard.UI.Components;

/// <summary>
/// Code-behind for the ChartWidgetsCard component.
/// </summary>
public partial class ChartWidgetsCard
{
    /// <summary>
    /// Gets or sets the card title.
    /// </summary>
    [Parameter]
    public string Title { get; set; } = "Charts";

    /// <summary>
    /// Gets or sets the collection of chart widgets to render inside the card.
    /// </summary>
    [Parameter]
    public IReadOnlyList<ChartWidgets.ChartWidget> Widgets { get; set; } = Array.Empty<ChartWidgets.ChartWidget>();
}
