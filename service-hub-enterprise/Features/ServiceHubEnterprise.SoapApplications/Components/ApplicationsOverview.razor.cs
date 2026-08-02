using Microsoft.AspNetCore.Components;
using Microsoft.AspNetCore.Components.Rendering;
using ServiceHubEnterprise.Grid.Components;
using ServiceHubEnterprise.SoapApplications.Core.Enums;
using ServiceHubEnterprise.SoapApplications.Models;

namespace ServiceHubEnterprise.SoapApplications.Components;

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

    /// <summary>
    /// Gets or sets whether the card is collapsed to its summary view.
    /// </summary>
    [Parameter] public bool Collapsed { get; set; }

    /// <summary>
    /// Invoked when the card's collapse state is toggled.
    /// </summary>
    [Parameter] public EventCallback<bool> OnToggle { get; set; }

    private int TotalApps => Apps.Count;
    private int EnabledApps => Apps.Count(a => a.Status == AppStatus.Enabled);
    private int DisabledApps => TotalApps - EnabledApps;
    private int TotalOperations => Apps.Sum(a => a.ApisCount);
}
