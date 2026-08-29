using Microsoft.AspNetCore.Components;
using OrbitHub.Dashboard.Application.DTOs;

namespace OrbitHub.Dashboard.UI.Components;

/// <summary>
/// Code-behind for the ActivityByUser component.
/// Superusers see all users' activity (current user highlighted);
/// other users see only their own activity.
/// </summary>
public partial class ActivityByUser
{
    private static readonly string[] Palette =
    [
        "#3b82f6", "#8b5cf6", "#10b981", "#f59e0b",
        "#ef4444", "#06b6d4", "#ec4899", "#84cc16"
    ];

    /// <summary>
    /// Gets or sets the card title.
    /// </summary>
    [Parameter] public string Title { get; set; } = "Activity by User";

    /// <summary>
    /// Gets or sets the activity log entries to render.
    /// </summary>
    [Parameter] public IReadOnlyList<RecentActivityDto> Activities { get; set; } = Array.Empty<RecentActivityDto>();

    /// <summary>
    /// Gets or sets the name of the current user.
    /// </summary>
    [Parameter] public string? CurrentUser { get; set; }

    /// <summary>
    /// Gets or sets whether the current user has the Superuser role.
    /// </summary>
    [Parameter] public bool IsSuperuser { get; set; }

    /// <summary>
    /// Gets the activity counts grouped by user, scoped to the current user unless a superuser.
    /// </summary>
    private IReadOnlyList<ActivityItem> Items
    {
        get
        {
            if (string.IsNullOrEmpty(CurrentUser))
            {
                return Array.Empty<ActivityItem>();
            }

            var grouped = Activities
                .Where(a => IsSuperuser || a.User.Equals(CurrentUser, StringComparison.OrdinalIgnoreCase))
                .GroupBy(a => a.User)
                .OrderByDescending(g => g.Count())
                .ToList();

            var max = grouped.Count > 0 ? grouped.Max(g => g.Count()) : 1;
            var paletteIndex = 0;

            return grouped
                .Select(g =>
                {
                    var isCurrent = g.Key.Equals(CurrentUser, StringComparison.OrdinalIgnoreCase);
                    var color = isCurrent ? "var(--sh-accent)" : Palette[paletteIndex++ % Palette.Length];
                    return new ActivityItem(g.Key, g.Count(), isCurrent, color, max > 0 ? g.Count() * 100 / max : 0);
                })
                .ToList();
        }
    }

    /// <summary>
    /// Represents an activity count for a single user.
    /// </summary>
    public record ActivityItem(string Label, int Count, bool IsCurrent, string Color, int Percent);
}
