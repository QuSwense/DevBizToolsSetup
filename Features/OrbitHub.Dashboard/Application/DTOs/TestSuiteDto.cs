namespace OrbitHub.Dashboard.Application.DTOs;

/// <summary>
/// Data transfer object for a test suite summary.
/// </summary>
public sealed class TestSuiteDto
{
    public string Name { get; set; } = string.Empty;
    public int TotalCases { get; set; }
    public int PassingCases { get; set; }
    public int TotalFiles { get; set; }
}
