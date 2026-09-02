using LinqToDB;
using LinqToDB.Async;
using Microsoft.Extensions.DependencyInjection;
using OrbitHub.SoapApplications.Models;

namespace OrbitHub.SoapApplications.Services;

/// <summary>
/// Singleton store for SOAP test cases, persisted to the database
/// via SoapDbContext. Test cases are attached to request files and define
/// extraction/assertion rules (XPath / JSON path / PDF) evaluated at execution time.
/// </summary>
public class SoapTestCaseStore(IServiceProvider serviceProvider)
{
    private readonly IServiceProvider _serviceProvider = serviceProvider;

    /// <summary>All test cases, ordered by application then file name.</summary>
    public IReadOnlyList<SoapTestCase> TestCases
    {
        get
        {
            using var scope = _serviceProvider.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();
            return [.. LoadTestCases(db, [.. db.SoapTestCases])
                .OrderBy(t => t.AppName).ThenBy(t => t.FileName).ThenBy(t => t.Name)];
        }
    }

    /// <summary>Returns enabled test cases attached to a specific file.</summary>
    public IReadOnlyList<SoapTestCase> GetEnabledForFile(string appName, string fileName)
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();
        var entities = db.SoapTestCases.Where(t => t.AppName == appName && t.FileName == fileName && t.Enabled).ToList();
        return [.. LoadTestCases(db, entities)];
    }

    /// <summary>Returns all test cases attached to a specific file (any enabled state).</summary>
    public IReadOnlyList<SoapTestCase> GetForFile(string appName, string fileName)
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();
        var entities = db.SoapTestCases.Where(t => t.AppName == appName && t.FileName == fileName).ToList();
        return [.. LoadTestCases(db, entities)];
    }

    /// <summary>Returns a test case by id, or null.</summary>
    public SoapTestCase? GetTestCase(string id)
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();
        var entity = db.SoapTestCases.FirstOrDefault(t => t.Id == id);
        return entity is not null ? LoadTestCases(db, [entity]).FirstOrDefault() : null;
    }

    /// <summary>Adds a test case and persists to the database.</summary>
    public async Task AddTestCaseAsync(SoapTestCase testCase)
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();
        await InsertTestCaseAsync(db, testCase);
    }

    /// <summary>Updates an existing test case and persists.</summary>
    public async Task UpdateTestCaseAsync(SoapTestCase testCase)
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();
        var existing = await db.SoapTestCases.FirstOrDefaultAsync(t => t.Id == testCase.Id);
        if (existing is null) return;

        existing.Name = testCase.Name;
        existing.Description = testCase.Description;
        existing.Enabled = testCase.Enabled;
        existing.UpdatedBy = testCase.UpdatedBy;
        existing.UpdatedAt = testCase.UpdatedAt;
        await db.UpdateAsync(existing);

        // Remove old extractors and re-add
        await db.SoapExtractors.Where(e => e.TestCaseId == testCase.Id).DeleteAsync();
        foreach (var e in testCase.Extractors)
        {
            await db.InsertAsync(new SoapExtractorEntity
            {
                Id = e.Id,
                TestCaseId = testCase.Id,
                Name = e.Name,
                Source = e.Source,
                Type = e.Type,
                Path = e.Path,
                ExpectedValue = e.ExpectedValue
            });
        }
    }

    /// <summary>Removes a test case and persists.</summary>
    public async Task DeleteTestCaseAsync(string id)
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();
        await db.SoapExtractors.Where(e => e.TestCaseId == id).DeleteAsync();
        await db.SoapTestCases.Where(t => t.Id == id).DeleteAsync();
    }

    /// <summary>Writes all test cases to the database (full replacement).</summary>
    public async Task PersistAllAsync(IReadOnlyList<SoapTestCase> testCases)
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();
        await db.SoapExtractors.DeleteAsync();
        await db.SoapTestCases.DeleteAsync();
        foreach (var tc in testCases)
        {
            await InsertTestCaseAsync(db, tc);
        }
    }

    // ── Mapping helpers ──

    private static IReadOnlyList<SoapTestCase> LoadTestCases(SoapDbContext db, IReadOnlyList<SoapTestCaseEntity> entities)
    {
        var ids = entities.Select(t => t.Id).ToList();
        var extractorsByTestCase = db.SoapExtractors.Where(e => ids.Contains(e.TestCaseId)).ToList().ToLookup(e => e.TestCaseId);

        return [.. entities.Select(entity => new SoapTestCase
        {
            Id = entity.Id,
            Name = entity.Name,
            Description = entity.Description ?? "",
            AppName = entity.AppName,
            FileName = entity.FileName,
            Enabled = entity.Enabled,
            CreatedBy = entity.CreatedBy,
            CreatedAt = entity.CreatedAt,
            UpdatedBy = entity.UpdatedBy,
            UpdatedAt = entity.UpdatedAt,
            Extractors = [.. extractorsByTestCase[entity.Id].Select(e => new SoapExtractor
            {
                Id = e.Id,
                Name = e.Name,
                Source = e.Source,
                Type = e.Type,
                Path = e.Path,
                ExpectedValue = e.ExpectedValue
            })]
        })];
    }

    private static async Task InsertTestCaseAsync(SoapDbContext db, SoapTestCase testCase)
    {
        await db.InsertAsync(new SoapTestCaseEntity
        {
            Id = testCase.Id,
            Name = testCase.Name,
            Description = testCase.Description,
            AppName = testCase.AppName,
            FileName = testCase.FileName,
            Enabled = testCase.Enabled,
            CreatedBy = testCase.CreatedBy,
            CreatedAt = testCase.CreatedAt,
            UpdatedBy = testCase.UpdatedBy,
            UpdatedAt = testCase.UpdatedAt
        });

        foreach (var e in testCase.Extractors)
        {
            await db.InsertAsync(new SoapExtractorEntity
            {
                Id = e.Id,
                TestCaseId = testCase.Id,
                Name = e.Name,
                Source = e.Source,
                Type = e.Type,
                Path = e.Path,
                ExpectedValue = e.ExpectedValue
            });
        }
    }
}
