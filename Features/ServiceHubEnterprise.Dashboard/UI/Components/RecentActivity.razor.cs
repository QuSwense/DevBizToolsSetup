using Microsoft.AspNetCore.Components;
using ServiceHubEnterprise.Ui.Models;

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

    /// <summary>
    /// Gets or sets whether the card is collapsed to its summary view.
    /// </summary>
    [Parameter] public bool Collapsed { get; set; }

    /// <summary>
    /// Invoked when the card's collapse state is toggled.
    /// </summary>
    [Parameter] public EventCallback<bool> OnToggle { get; set; }

    private DateRange _range = DateRange.LastDays(7);
    private string _userFilter = string.Empty;

    private void ApplyRange(DateRange? range) => _range = range ?? DateRange.LastDays(7);

    private IEnumerable<ActivityEntry> Filtered =>
        Activities
            .Where(a => _range.Includes(a.Timestamp))
            .Where(a => string.IsNullOrEmpty(_userFilter) || a.User.Equals(_userFilter, StringComparison.OrdinalIgnoreCase))
            .OrderByDescending(a => a.Timestamp)
            .Take(MaxItems);

    // ── Summary (collapsed view) computed props ────────────────────────

    private IEnumerable<ActivityEntry> InRangeActivities =>
        Activities.Where(a => _range.Includes(a.Timestamp));

    private int RangeActivityCount => InRangeActivities.Count();

    private int RangeActiveUsers =>
        InRangeActivities.Select(a => a.User).Distinct(StringComparer.OrdinalIgnoreCase).Count();

    private string LatestActivityTime =>
        InRangeActivities.Any()
            ? InRangeActivities.Max(a => a.Timestamp).ToString("MMM dd, HH:mm")
            : "—";
}
