using Microsoft.AspNetCore.Components;
using OrbitHub.Grid.Components;
using OrbitHub.SoapApplications.Models;
using OrbitHub.Ui.Models;

namespace OrbitHub.SoapApplications.Components;

/// <summary>
/// Code-behind for the Request Files overview section card.
/// Shows per-application file totals and a drill-down grid, filtered by app and date range.
/// </summary>
public partial class RequestFilesOverview
{
    /// <summary>
    /// Gets or sets the SOAP request files to display.
    /// </summary>
    [Parameter] public IReadOnlyList<SoapRequestFile> Files { get; set; } = [];

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

    private List<GridColumn<SoapRequestFile>> _columns = [];

    /// <summary>
    /// Represents a per-application file summary row.
    /// </summary>
    public record PerAppRow(string AppName, int Active, int Total, int ActivePct);

    private IReadOnlyList<string> AppNames => Files
        .Select(f => f.AppName)
        .Distinct(StringComparer.OrdinalIgnoreCase)
        .OrderBy(n => n)
        .ToList();

    private int ActiveCount => Files.Count(f => f.Status.Equals("active", StringComparison.OrdinalIgnoreCase));
    private int InactiveCount => Files.Count - ActiveCount;

    private IReadOnlyList<PerAppRow> PerAppRows
    {
        get
        {
            var inRange = InRangeFiles(Files).ToList();
            return AppNames
                .Select(app =>
                {
                    var rows = inRange.Where(f => f.AppName.Equals(app, StringComparison.OrdinalIgnoreCase)).ToList();
                    var active = rows.Count(f => f.Status.Equals("active", StringComparison.OrdinalIgnoreCase));
                    return new PerAppRow(app, active, rows.Count, rows.Count > 0 ? active * 100 / rows.Count : 0);
                })
                .Where(r => r.Total > 0)
                .ToList();
        }
    }

    private IEnumerable<SoapRequestFile> InRangeFiles(IEnumerable<SoapRequestFile> source)
        => source.Where(f => f.UpdatedAt.HasValue && _range.Includes(f.UpdatedAt.Value));

    /// <inheritdoc />
    protected override void OnInitialized()
    {
        _columns =
        [
            new() { Title = "File Name", Sortable = true, Field = f => f.FileName, CssClass = "mono-text" },
            new() { Title = "Application", Sortable = true, Field = f => f.AppName },
            new()
            {
                Title = "Status", Sortable = true, Field = f => f.Status, Width = "100px",
                Template = ctx => builder =>
                {
                    var active = ctx.Status.Equals("active", StringComparison.OrdinalIgnoreCase);
                    builder.OpenElement(0, "span");
                    builder.AddAttribute(1, "class", active ? "sb-badge sb-enabled" : "sb-badge sb-disabled");
                    builder.AddContent(2, active ? "Active" : "Inactive");
                    builder.CloseElement();
                }
            },
            new() { Title = "Operation", Sortable = true, Field = f => f.ApiPath },
            new() { Title = "Updated", Sortable = true, Field = f => f.UpdatedAt.HasValue ? f.UpdatedAt.Value.ToString("yyyy-MM-dd") : "—", Width = "120px" }
        ];
    }
}
