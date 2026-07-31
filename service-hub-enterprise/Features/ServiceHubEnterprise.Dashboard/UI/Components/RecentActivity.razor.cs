using Microsoft.AspNetCore.Components;
using ServiceHubEnterprise.Dashboard.UI.Models;

namespace ServiceHubEnterprise.Dashboard.UI.Components;

/// <summary>
/// Code-behind for the RecentActivity component.
/// A full-width activity feed with date-range and user filters.
/// </summary>
public partial class RecentActivity
{
    /// <summary>
    /// Represents a single activity log entry with an absolute timestamp.
    /// </summary>
    public record ActivityEntry(string User, string Action, DateTime Timestamp)
    {
        public string Time => Timestamp.ToString("MMM dd, HH:mm");
    }

    /// <summary>
    /// Gets or sets the card title.
    /// </summary>
    [Parameter] public string Title { get; set; } = "Recent Activity";

    /// <summary>
    /// Gets or sets whether to show the "View All" link.
    /// </summary>
    [Parameter] public bool ShowViewAll { get; set; }

    /// <summary>
    /// Gets or sets the "View All" link href.
    /// </summary>
    [Parameter] public string ViewAllHref { get; set; } = "#";

    /// <summary>
    /// Gets or sets the list of recent activity entries to display.
    /// </summary>
    [Parameter]
    public IReadOnlyList<ActivityEntry> Activities { get; set; } = Array.Empty<ActivityEntry>();

    /// <summary>
    /// Gets or sets the list of user names available in the user filter.
    /// </summary>
    [Parameter]
    public IReadOnlyList<string> Users { get; set; } = Array.Empty<string>();

    /// <summary>
    /// Gets or sets the maximum number of entries to display after filtering.
    /// </summary>
    [Parameter] public int MaxItems { get; set; } = 10;

    private DateRange _range = DateRange.LastDays(7);
    private string _userFilter = string.Empty;

    private void ApplyRange(DateRange? range) => _range = range ?? DateRange.LastDays(7);

    private IEnumerable<ActivityEntry> Filtered =>
        Activities
            .Where(a => _range.Includes(a.Timestamp))
            .Where(a => string.IsNullOrEmpty(_userFilter) || a.User.Equals(_userFilter, StringComparison.OrdinalIgnoreCase))
            .OrderByDescending(a => a.Timestamp)
            .Take(MaxItems);
}
