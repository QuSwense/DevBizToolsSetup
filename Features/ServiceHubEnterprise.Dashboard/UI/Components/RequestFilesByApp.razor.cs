using Microsoft.AspNetCore.Components;
using ServiceHubEnterprise.Dashboard.Application.DTOs;

namespace ServiceHubEnterprise.Dashboard.UI.Components;

/// <summary>
/// Code-behind for the RequestFilesByApp component.
/// Groups request files per application with status and owner filters.
/// </summary>
public partial class RequestFilesByApp
{
    private string _statusFilter = "all";
    private bool _onlyMine;

    private static readonly string[] Palette =
    [
        "#3b82f6", "#8b5cf6", "#10b981", "#f59e0b",
        "#ef4444", "#06b6d4", "#ec4899", "#84cc16"
    ];

    /// <summary>
    /// Gets or sets the card title.
    /// </summary>
    [Parameter] public string Title { get; set; } = "Request Files";

    /// <summary>
    /// Gets or sets the request files to render.
    /// </summary>
    [Parameter] public IReadOnlyList<RequestFileDto> Files { get; set; } = Array.Empty<RequestFileDto>();

    /// <summary>
    /// Gets or sets the name of the current user for the "Only mine" filter.
    /// </summary>
    [Parameter] public string? CurrentUser { get; set; }

    /// <summary>
    /// Gets the filtered files grouped by application, ordered by count descending.
    /// </summary>
    private IReadOnlyList<AppFileCount> Grouped
    {
        get
        {
            var filtered = Files.Where(f => MatchesStatus(f) && MatchesUser(f)).ToList();

            return filtered
                .GroupBy(f => f.AppName)
                .OrderByDescending(g => g.Count())
                .Select((g, i) => new AppFileCount(g.Key, g.Count(), Palette[i % Palette.Length]))
                .ToList();
        }
    }

    private int DisplayedCount => Grouped.Sum(g => g.Count);

    private bool MatchesStatus(RequestFileDto file) =>
        _statusFilter switch
        {
            "enabled" => file.Status.Equals("active", StringComparison.OrdinalIgnoreCase),
            "disabled" => file.Status.Equals("inactive", StringComparison.OrdinalIgnoreCase),
            _ => true
        };

    private bool MatchesUser(RequestFileDto file) =>
        !_onlyMine
        || string.IsNullOrEmpty(CurrentUser)
        || file.CreatedBy.Equals(CurrentUser, StringComparison.OrdinalIgnoreCase);

    private void ShowAll() => _statusFilter = "all";

    private void ShowEnabled() => _statusFilter = "enabled";

    private void ShowDisabled() => _statusFilter = "disabled";

    /// <summary>
    /// Represents the file count for a single application.
    /// </summary>
    public record AppFileCount(string AppName, int Count, string Color);
}
