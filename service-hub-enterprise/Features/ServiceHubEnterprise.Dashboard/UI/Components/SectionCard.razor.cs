using Microsoft.AspNetCore.Components;
using ServiceHubEnterprise.Dashboard.UI.Models;

namespace ServiceHubEnterprise.Dashboard.UI.Components;

/// <summary>
/// Code-behind for the SectionCard component.
/// A full-row dashboard section with an optional date-range filter dialog.
/// </summary>
public partial class SectionCard
{
    /// <summary>
    /// Gets or sets the section title.
    /// </summary>
    [Parameter] public string Title { get; set; } = string.Empty;

    /// <summary>
    /// Gets or sets an optional emoji/icon shown next to the title.
    /// </summary>
    [Parameter] public string? Icon { get; set; }

    /// <summary>
    /// Gets or sets an optional subtitle shown under the title.
    /// </summary>
    [Parameter] public string? Subtitle { get; set; }

    /// <summary>
    /// Gets or sets the active date-range filter; null hides the filter dialog.
    /// </summary>
    [Parameter] public DateRange? Filter { get; set; }

    /// <summary>
    /// Invoked when the user applies or clears the date-range filter.
    /// </summary>
    [Parameter] public EventCallback<DateRange?> OnFilterChanged { get; set; }

    /// <summary>
    /// Gets or sets optional header actions rendered beside the filter pill.
    /// </summary>
    [Parameter] public RenderFragment? HeaderActions { get; set; }

    /// <summary>
    /// Gets or sets the main content of the section.
    /// </summary>
    [Parameter] public RenderFragment? ChildContent { get; set; }

    /// <summary>
    /// Gets or sets an optional footer rendered below the main content.
    /// </summary>
    [Parameter] public RenderFragment? Footer { get; set; }

    private bool _showFilter;

    private void ToggleFilter() => _showFilter = !_showFilter;

    private void CloseFilter() => _showFilter = false;

    private async Task HandleFilterChanged(DateRange? range)
    {
        _showFilter = false;
        await OnFilterChanged.InvokeAsync(range);
    }
}
