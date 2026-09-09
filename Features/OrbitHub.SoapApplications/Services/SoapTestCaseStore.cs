using OrbitHub.SoapApplications.Models;

namespace OrbitHub.SoapApplications.Services;

/// <summary>
/// In-memory store for SOAP test cases.
/// The legacy SoapManagement tables are no longer in the generated data model,
/// so the feature keeps its original public API but stores the items in memory.
/// </summary>
public class SoapTestCaseStore(IServiceProvider serviceProvider)
{
    private readonly IServiceProvider _serviceProvider = serviceProvider;
    private readonly List<SoapTestCase> _testCases = [];

    /// <summary>All test cases, ordered by application then file name.</summary>
    public IReadOnlyList<SoapTestCase> TestCases => [.. _testCases.OrderBy(t => t.AppName).ThenBy(t => t.FileName).ThenBy(t => t.Name)];

    /// <summary>Returns enabled test cases attached to a specific file.</summary>
    public IReadOnlyList<SoapTestCase> GetEnabledForFile(string appName, string fileName)
        => [.. _testCases.Where(t => t.AppName == appName && t.FileName == fileName && t.Enabled)];

    /// <summary>Returns all test cases attached to a specific file (any enabled state).</summary>
    public IReadOnlyList<SoapTestCase> GetForFile(string appName, string fileName)
        => [.. _testCases.Where(t => t.AppName == appName && t.FileName == fileName)];

    /// <summary>Returns a test case by id, or null.</summary>
    public SoapTestCase? GetTestCase(string id) => _testCases.FirstOrDefault(t => t.Id == id);

    /// <summary>Adds a test case and persists to the in-memory catalog.</summary>
    public Task AddTestCaseAsync(SoapTestCase testCase)
    {
        _testCases.RemoveAll(t => t.Id == testCase.Id);
        _testCases.Add(testCase);
        return Task.CompletedTask;
    }

    /// <summary>Updates an existing test case in memory.</summary>
    public Task UpdateTestCaseAsync(SoapTestCase testCase)
    {
        var existing = _testCases.FirstOrDefault(t => t.Id == testCase.Id);
        if (existing is null)
        {
            _testCases.Add(testCase);
            return Task.CompletedTask;
        }

        existing.Name = testCase.Name;
        existing.Description = testCase.Description;
        existing.AppName = testCase.AppName;
        existing.FileName = testCase.FileName;
        existing.Enabled = testCase.Enabled;
        existing.CreatedBy = testCase.CreatedBy;
        existing.CreatedAt = testCase.CreatedAt;
        existing.UpdatedBy = testCase.UpdatedBy;
        existing.UpdatedAt = testCase.UpdatedAt;
        existing.Extractors = testCase.Extractors;
        return Task.CompletedTask;
    }

    /// <summary>Removes a test case from the in-memory catalog.</summary>
    public Task DeleteTestCaseAsync(string id)
    {
        _testCases.RemoveAll(t => t.Id == id);
        return Task.CompletedTask;
    }

    /// <summary>Writes all test cases to the in-memory catalog (full replacement).</summary>
    public Task PersistAllAsync(IReadOnlyList<SoapTestCase> testCases)
    {
        _testCases.Clear();
        _testCases.AddRange(testCases);
        return Task.CompletedTask;
    }
}
