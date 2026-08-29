using Microsoft.AspNetCore.Components;

namespace OrbitHub.Dashboard.UI.Components;

/// <summary>
/// Code-behind for the PassRateDonut component.
/// Shows the overall test case pass rate as a donut chart.
/// </summary>
public partial class PassRateDonut
{
    /// <summary>
    /// Gets or sets the card title.
    /// </summary>
    [Parameter] public string Title { get; set; } = "Test Pass Rate";

    /// <summary>
    /// Gets or sets the number of passing cases.
    /// </summary>
    [Parameter] public int Passing { get; set; }

    /// <summary>
    /// Gets or sets the total number of cases.
    /// </summary>
    [Parameter] public int Total { get; set; }

    private int Failing => Total - Passing;

    private int PassPct => Total > 0 ? Passing * 100 / Total : 0;

    private int FailPct => Total > 0 ? 100 - PassPct : 0;
}
