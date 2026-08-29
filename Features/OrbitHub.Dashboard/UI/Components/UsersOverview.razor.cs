using Microsoft.AspNetCore.Components;
using OrbitHub.Dashboard.Application.DTOs;
using OrbitHub.Ui.Models;

namespace OrbitHub.Dashboard.UI.Components;

/// <summary>
/// Code-behind for the UsersOverview section card.
/// Shows user totals, user types, and active-user stats over a selectable date range.
/// </summary>
public partial class UsersOverview
{
    /// <summary>
    /// Gets or sets the list of application users.
    /// </summary>
    [Parameter] public IReadOnlyList<UserDto> Users { get; set; } = Array.Empty<UserDto>();

    /// <summary>
    /// Gets or sets the timestamped user activity log.
    /// </summary>
    [Parameter] public IReadOnlyList<UserActivityDto> Activities { get; set; } = Array.Empty<UserActivityDto>();

    /// <summary>
    /// Gets or sets whether the card is collapsed to its summary view.
    /// </summary>
    [Parameter] public bool Collapsed { get; set; }

    /// <summary>
    /// Invoked when the card's collapse state is toggled.
    /// </summary>
    [Parameter] public EventCallback<bool> OnToggle { get; set; }

    private DateRange _range = DateRange.LastDays(7);

    private void ApplyRange(DateRange? range) => _range = range ?? DateRange.LastDays(7);

    private static DateTime? TryParseTimestamp(string value)
        => DateTime.TryParse(value, out var dt) ? dt : null;

    private IEnumerable<UserActivityDto> FilteredActivities =>
        Activities.Where(a => TryParseTimestamp(a.Timestamp) is DateTime dt && _range.Includes(dt));

    private int ActiveCount =>
        FilteredActivities.Select(a => a.UserName).Distinct(StringComparer.OrdinalIgnoreCase).Count();

    private int ActiveSharePct => Users.Count > 0 ? ActiveCount * 100 / Users.Count : 0;

    private IReadOnlyList<string> UserTypes =>
        Users.Select(u => u.Role).Distinct(StringComparer.OrdinalIgnoreCase).OrderBy(r => r).ToList();

    private IReadOnlyList<(string User, int Count)> TopActiveUsers =>
        FilteredActivities
            .GroupBy(a => a.UserName, StringComparer.OrdinalIgnoreCase)
            .Select(g => (User: g.Key, Count: g.Count()))
            .OrderByDescending(x => x.Count)
            .Take(5)
            .ToList();

    private int MaxActivityCount => TopActiveUsers.Count > 0 ? TopActiveUsers[0].Count : 0;
}
