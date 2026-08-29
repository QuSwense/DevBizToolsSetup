using Microsoft.AspNetCore.Components;
using ServiceHubEnterprise.Ui.Models;

namespace ServiceHubEnterprise.Ui.Components;

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
    /// Gets or sets optional information shown on a separate line under the header row.
    /// </summary>
    [Parameter] public string? Information { get; set; }

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

    /// <summary>
    /// Gets or sets whether the section supports expand/collapse.
    /// When false (default) the section renders exactly as before and no toggle is shown.
    /// </summary>
    [Parameter] public bool Collapsible { get; set; }

    /// <summary>
    /// Gets or sets whether the section is currently collapsed (summary view).
    /// Only applies when <see cref="Collapsible"/> is true.
    /// </summary>
    [Parameter] public bool Collapsed { get; set; }

    /// <summary>
    /// Invoked when the user toggles the collapse state; receives the new collapsed value.
    /// </summary>
    [Parameter] public EventCallback<bool> OnToggle { get; set; }

    /// <summary>
    /// Gets or sets the compact summary content shown while the section is collapsed.
    /// </summary>
    [Parameter] public RenderFragment? Summary { get; set; }

    private bool _showFilter;

    private void ToggleFilter() => _showFilter = !_showFilter;

    private void CloseFilter() => _showFilter = false;

    private async Task HandleFilterChanged(DateRange? range)
    {
        _showFilter = false;
        await OnFilterChanged.InvokeAsync(range);
    }

    private async Task Toggle() => await OnToggle.InvokeAsync(!Collapsed);
}
