using Microsoft.AspNetCore.Components;

namespace ServiceHubEnterprise.Ui.Components;

/// <summary>
/// Code-behind for the KpiTile component.
/// A compact label/value stat tile used inside section cards.
/// </summary>
public partial class KpiTile
{
    /// <summary>
    /// Gets or sets the tile label.
    /// </summary>
    [Parameter] public string Label { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets the primary value text.
    /// </summary>
    [Parameter] public string Value { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets an optional supporting line under the value.
    /// </summary>
    [Parameter] public string? Sub { get; set; }

    /// <summary>
    /// Gets or sets an optional value color (CSS color).
    /// </summary>
    [Parameter] public string? Color { get; set; }

    /// <summary>
    /// Gets or sets an optional emoji/icon shown in the header.
    /// </summary>
    [Parameter] public string? Icon { get; set; }
}
