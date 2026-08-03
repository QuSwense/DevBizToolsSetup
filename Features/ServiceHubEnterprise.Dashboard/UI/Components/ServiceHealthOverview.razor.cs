using Microsoft.AspNetCore.Components;
using ServiceHubEnterprise.Dashboard.Application.DTOs;
using ServiceHubEnterprise.Ui.Components;
using ServiceHubEnterprise.Ui.Models;

namespace ServiceHubEnterprise.Dashboard.UI.Components;

/// <summary>
/// Code-behind for the ServiceHealthOverview section card.
/// Shows current service status plus uptime and active-duration over a selectable date range.
/// </summary>
public partial class ServiceHealthOverview
{
    /// <summary>
    /// Gets or sets the current service health snapshot.
    /// </summary>
    [Parameter] public IReadOnlyList<ServiceHealthDto> Services { get; set; } = Array.Empty<ServiceHealthDto>();

    /// <summary>
    /// Gets or sets the time-series service health samples.
    /// </summary>
    [Parameter] public IReadOnlyList<ServiceUptimeDto> Uptime { get; set; } = Array.Empty<ServiceUptimeDto>();

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

    private IEnumerable<ServiceUptimeDto> FilteredSamples =>
        Uptime.Where(u => TryParseTimestamp(u.Timestamp) is DateTime dt && _range.Includes(dt));

    private int TotalNow => Services.Count;
    private int OperationalNow => Services.Count(s => s.Status.Equals("ok", StringComparison.OrdinalIgnoreCase));
    private int DegradedNow => Services.Count(s => s.Status.Contains("degrad", StringComparison.OrdinalIgnoreCase));
    private int DownNow => Services.Count(s => s.Status.Equals("down", StringComparison.OrdinalIgnoreCase));

    private TimeSpan DataSpan
    {
        get
        {
            var times = FilteredSamples
                .Select(u => TryParseTimestamp(u.Timestamp))
                .Where(d => d.HasValue)
                .Select(d => d!.Value)
                .ToList();

            if (times.Count == 0)
            {
                return TimeSpan.FromDays(1);
            }

            var span = times.Max() - times.Min();
            return span > TimeSpan.Zero ? span : TimeSpan.FromDays(1);
        }
    }

    /// <summary>
    /// Represents a per-service health summary row.
    /// </summary>
    public record HealthRow(string Name, string CurrentStatus, int UpPct, string UptimeText, IReadOnlyList<TimelineStrip.Segment> Segments);

    private IReadOnlyList<HealthRow> Rows =>
        Services.Select(s =>
        {
            var samples = FilteredSamples.Where(u => u.ServiceName.Equals(s.Name, StringComparison.OrdinalIgnoreCase)).ToList();
            var ok = samples.Count(x => x.Status.Equals("ok", StringComparison.OrdinalIgnoreCase));
            var degraded = samples.Count(x => x.Status.Equals("degraded", StringComparison.OrdinalIgnoreCase));
            var down = samples.Count(x => x.Status.Equals("down", StringComparison.OrdinalIgnoreCase));
            var total = samples.Count;
            var upPct = total > 0 ? ok * 100 / total : 0;

            var segments = new List<TimelineStrip.Segment>();
            if (total > 0)
            {
                if (ok > 0)
                {
                    segments.Add(new TimelineStrip.Segment(ok * 100.0 / total, "var(--sh-success)", $"{ok} ok"));
                }

                if (degraded > 0)
                {
                    segments.Add(new TimelineStrip.Segment(degraded * 100.0 / total, "var(--sh-warning)", $"{degraded} degraded"));
                }

                if (down > 0)
                {
                    segments.Add(new TimelineStrip.Segment(down * 100.0 / total, "var(--sh-danger)", $"{down} down"));
                }
            }

            return new HealthRow(s.Name, s.Status, upPct, BuildUptimeText(ok, total), segments);
        }).ToList();

    private string BuildUptimeText(int ok, int total)
    {
        if (total == 0)
        {
            return "no data in range";
        }

        var up = DataSpan * ok / total;
        return $"up {FormatSpan(up)} / {FormatSpan(DataSpan)}";
    }

    private static string FormatSpan(TimeSpan t)
    {
        if (t.TotalDays >= 1)
        {
            return $"{(int)t.TotalDays}d {t.Hours}h";
        }

        if (t.TotalHours >= 1)
        {
            return $"{(int)t.TotalHours}h {t.Minutes}m";
        }

        return $"{(int)t.TotalMinutes}m";
    }

    private string StatusBadgeClass(string status) => status.ToLowerInvariant() switch
    {
        "ok" => "sb-ok",
        "degraded" => "sb-degraded",
        "down" => "sb-down",
        _ => "sb-none"
    };
}
