using Microsoft.AspNetCore.Components;

namespace OrbitHub.Dashboard.UI.Components;

/// <summary>
/// Code-behind for the TestSuiteProgress component.
/// </summary>
public partial class TestSuiteProgress
{
    /// <summary>
    /// Gets or sets the card title.
    /// </summary>
    [Parameter] public string Title { get; set; } = "Test Suites";

    /// <summary>
    /// Gets or sets the passing summary text (e.g. "25 / 84 passing").
    /// </summary>
    [Parameter] public string? PassingSummary { get; set; }

    /// <summary>
    /// Gets or sets the list of test suites.
    /// </summary>
    [Parameter]
    public IReadOnlyList<TestSuiteItem> Suites { get; set; } = Array.Empty<TestSuiteItem>();

    /// <summary>
    /// Represents a single test suite entry.
    /// </summary>
    public record TestSuiteItem(string Name, int Cases, int Files);
}
