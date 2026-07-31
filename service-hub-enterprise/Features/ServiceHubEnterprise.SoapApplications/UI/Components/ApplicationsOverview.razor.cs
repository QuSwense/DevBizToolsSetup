using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Rendering;
using ServiceHubEnterprise.Grid.Components;
using ServiceHubEnterprise.SoapApplications.Services;

namespace ServiceHubEnterprise.SoapApplications.UI.Components;

/// <summary>
/// Code-behind for the Applications overview section card.
/// Shows SOAP app totals, enabled/disabled split, and a drill-down grid.
/// </summary>
public partial class ApplicationsOverview
{
    /// <summary>
    /// Gets or sets the SOAP applications to display.
    /// </summary>
    [Parameter] public IReadOnlyList<SoapApp> Apps { get; set; } = [];

    private int TotalApps => Apps.Count;
    private int EnabledApps => Apps.Count(a => a.Status.Equals("enabled", StringComparison.OrdinalIgnoreCase));
    private int DisabledApps => TotalApps - EnabledApps;
    private int TotalOperations => Apps.Sum(a => a.ApisCount);
}
