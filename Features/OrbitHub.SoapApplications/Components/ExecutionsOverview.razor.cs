using Microsoft.AspNetCore.Components;
using OrbitHub.Grid.Components;
using OrbitHub.SoapApplications.Models;
using OrbitHub.Ui.Components;
using OrbitHub.Ui.Models;

namespace OrbitHub.SoapApplications.Components;

/// <summary>
/// Code-behind for the Executions overview section card.
/// Shows SOAP execution success/failure stats over the selected date range, plus a drill-down grid.
/// </summary>
public partial class ExecutionsOverview
{
    /// <summary>
    /// Gets or sets the SOAP execution history (already filtered to appType == "soap").
    /// </summary>
    [Parameter] public IReadOnlyList<SoapExecution> Executions { get; set; } = [];

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

    private List<GridColumn<SoapExecution>> _columns = [];
    private string _searchText = "";
    private string? _sortColumn = null;
    private bool _sortAscending = true;

    private IReadOnlyList<SoapExecution> InRangeExecutions
    {
        get
        {
            var result = Executions
                .Select(e => (e, dt: e.TryGetTimestamp()))
                .Where(x => x.dt.HasValue && _range.Includes(x.dt.Value))
                .Select(x => x.e)
                .ToList();

            if (!string.IsNullOrWhiteSpace(_searchText))
            {
                var q = _searchText.Trim();
                result = [.. result.Where(e =>
                    e.AppName.Contains(q, StringComparison.OrdinalIgnoreCase) ||
                    e.FileName.Contains(q, StringComparison.OrdinalIgnoreCase) ||
                    e.TriggeredBy.Contains(q, StringComparison.OrdinalIgnoreCase))];
            }

            return (_sortColumn, _sortAscending) switch
            {
                ("Id", true) or (null, _) => [.. result.OrderBy(e => e.Id)],
                ("Id", false) => [.. result.OrderByDescending(e => e.Id)],
                ("AppName", true) => [.. result.OrderBy(e => e.AppName)],
                ("AppName", false) => [.. result.OrderByDescending(e => e.AppName)],
                ("Status", true) => [.. result.OrderBy(e => e.Status)],
                ("Status", false) => [.. result.OrderByDescending(e => e.Status)],
                ("ExecutedAt", true) => [.. result.OrderBy(e => e.ExecutedAt)],
                ("ExecutedAt", false) => [.. result.OrderByDescending(e => e.ExecutedAt)],
                _ => result
            };
        }
    }

    private int SuccessCount => InRangeExecutions.Count(e => e.Status.Equals("success", StringComparison.OrdinalIgnoreCase));
    private int FailCount => InRangeExecutions.Count - SuccessCount;

    private string AvgDurationText
    {
        get
        {
            var inRange = InRangeExecutions;
            if (inRange.Count == 0)
            {
                return "—";
            }

            var avgMs = inRange.Average(e => e.DurationMs);
            return $"{avgMs / 1000.0:0.0}s";
        }
    }

    private IReadOnlyList<TimelineStrip.Segment> TimelineSegments
    {
        get
        {
            var total = InRangeExecutions.Count;
            if (total == 0)
            {
                return [];
            }

            var ok = SuccessCount;
            var fail = total - ok;
            return
            [
                new TimelineStrip.Segment(ok * 100.0 / total, "var(--sh-success)", $"{ok} success"),
                new TimelineStrip.Segment(fail * 100.0 / total, "var(--sh-danger)", $"{fail} failed")
            ];
        }
    }

    /// <inheritdoc />
    protected override void OnInitialized()
    {
        _columns =
        [
            new() { Title = "Execution", Sortable = true, Field = e => e.Id, Width = "110px", CssClass = "cell-id" },
            new() { Title = "Application", Sortable = true, Field = e => e.AppName },
            new() { Title = "Request File", Sortable = true, Field = e => e.FileName, CssClass = "mono-text" },
            new()
            {
                Title = "Status", Sortable = true, Field = e => e.Status, Width = "100px",
                Template = ctx => builder =>
                {
                    var ok = ctx.Status.Equals("success", StringComparison.OrdinalIgnoreCase);
                    builder.OpenElement(0, "span");
                    builder.AddAttribute(1, "class", ok ? "sb-badge sb-passed" : "sb-badge sb-failed");
                    builder.AddContent(2, ok ? "Success" : "Failed");
                    builder.CloseElement();
                }
            },
            new() { Title = "Duration", Sortable = true, Field = e => $"{e.DurationMs / 1000.0:0.0}s", Width = "90px" },
            new() { Title = "Executed", Sortable = true, Field = e => e.ExecutedAt, Width = "150px" },
            new() { Title = "Triggered By", Sortable = true, Field = e => e.TriggeredBy }
        ];
    }
}
