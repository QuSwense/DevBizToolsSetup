using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Rendering;
using ServiceHubEnterprise.Grid.Components;
using ServiceHubEnterprise.SoapApplications.Models;
using ServiceHubEnterprise.Ui.Components;
using ServiceHubEnterprise.Ui.Models;

namespace ServiceHubEnterprise.SoapApplications.Components;

/// <summary>
/// Code-behind for the WSDL Sync overview section card.
/// Shows sync record totals, a sync-status timeline over the selected date range, and a drill-down grid.
/// </summary>
public partial class WsdlSyncOverview
{
    /// <summary>
    /// Gets or sets the WSDL sync records.
    /// </summary>
    [Parameter] public IReadOnlyList<WsdlSyncRecord> Records { get; set; } = [];

    /// <summary>
    /// Gets or sets the WSDL version snapshots.
    /// </summary>
    [Parameter] public IReadOnlyList<WsdlVersionEntry> Versions { get; set; } = [];

    /// <summary>
    /// Gets or sets the WSDL sync history time series.
    /// </summary>
    [Parameter] public IReadOnlyList<WsdlSyncHistoryPoint> SyncHistory { get; set; } = [];

    private DateRange _range = DateRange.LastDays(7);

    private void ApplyRange(DateRange? range) => _range = range ?? DateRange.LastDays(7);

    private List<GridColumn<WsdlSyncRecord>> _columns = [];

    private int SyncedCount => Records.Count(r => r.Status.Equals("synced", StringComparison.OrdinalIgnoreCase));
    private int FailedCount => Records.Count(r => r.Status.Equals("failed", StringComparison.OrdinalIgnoreCase));
    private int ParsingCount => Records.Count(r => r.Status.Equals("parsing", StringComparison.OrdinalIgnoreCase));

    private IReadOnlyList<TimelineStrip.Segment> TimelineSegments
    {
        get
        {
            var points = SyncHistory
                .Select(h => (h, dt: h.TryGetDate()))
                .Where(x => x.dt.HasValue && _range.Includes(x.dt.Value))
                .ToList();
            var total = points.Count;
            if (total == 0)
            {
                return [];
            }

            var synced = points.Count(x => x.h.Status.Equals("synced", StringComparison.OrdinalIgnoreCase));
            var failed = points.Count(x => x.h.Status.Equals("failed", StringComparison.OrdinalIgnoreCase));
            var parsing = points.Count(x => x.h.Status.Equals("parsing", StringComparison.OrdinalIgnoreCase));

            return
            [
                new TimelineStrip.Segment(synced * 100.0 / total, "var(--sh-success)", $"{synced} synced"),
                new TimelineStrip.Segment(failed * 100.0 / total, "var(--sh-danger)", $"{failed} failed"),
                new TimelineStrip.Segment(parsing * 100.0 / total, "var(--sh-warning)", $"{parsing} parsing")
            ];
        }
    }

    /// <inheritdoc />
    protected override void OnInitialized()
    {
        _columns =
        [
            new() { Title = "Application", Sortable = true, Field = r => r.AppName },
            new()
            {
                Title = "Source", Sortable = true, Field = r => r.SourceType, Width = "100px",
                Template = ctx => builder =>
                {
                    var isUrl = ctx.SourceType.Equals("url", StringComparison.OrdinalIgnoreCase);
                    builder.OpenElement(0, "span");
                    builder.AddAttribute(1, "class", "cell-id");
                    builder.AddContent(2, isUrl ? "URL" : "Upload");
                    builder.CloseElement();
                }
            },
            new()
            {
                Title = "Status", Sortable = true, Field = r => r.Status, Width = "110px",
                Template = ctx => builder =>
                {
                    var cls = ctx.Status switch
                    {
                        _ when ctx.Status.Equals("synced", StringComparison.OrdinalIgnoreCase) => "sb-badge sb-synced",
                        _ when ctx.Status.Equals("failed", StringComparison.OrdinalIgnoreCase) => "sb-badge sb-failed",
                        _ => "sb-badge sb-parsing"
                    };
                    var label = ctx.Status switch
                    {
                        _ when ctx.Status.Equals("synced", StringComparison.OrdinalIgnoreCase) => "Synced",
                        _ when ctx.Status.Equals("failed", StringComparison.OrdinalIgnoreCase) => "Failed",
                        _ => "Parsing"
                    };
                    builder.OpenElement(0, "span");
                    builder.AddAttribute(1, "class", cls);
                    builder.AddContent(2, label);
                    builder.CloseElement();
                }
            },
            new() { Title = "Uploaded", Sortable = true, Field = r => r.UploadedAt, Width = "150px" },
            new() { Title = "Versions", Sortable = true, Field = r => r.VersionCount, Width = "100px" }
        ];
    }
}
