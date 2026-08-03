namespace ServiceHubEnterprise.Dashboard.Core.Entities;

/// <summary>
/// Represents a single historical run of a test suite.
/// </summary>
public sealed class TestSuiteHistoryEntity
{
    public string Id { get; set; } = string.Empty;
    public string SuiteName { get; set; } = string.Empty;
    public string ExecutedAt { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public int TotalCases { get; set; }
    public int PassingCases { get; set; }
    public int DurationMs { get; set; }
}
