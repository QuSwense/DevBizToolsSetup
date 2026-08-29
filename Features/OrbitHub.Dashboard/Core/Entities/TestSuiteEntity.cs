namespace OrbitHub.Dashboard.Core.Entities;

/// <summary>
/// Represents a test suite tracked on the dashboard.
/// </summary>
public sealed class TestSuiteEntity
{
    public string Name { get; set; } = string.Empty;
    public int TotalCases { get; set; }
    public int PassingCases { get; set; }
    public int TotalFiles { get; set; }
}
