using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using ServiceHubEnterprise.Data;
using ServiceHubEnterprise.Data.Entities;
using ServiceHubEnterprise.SoapApplications.Models;

namespace ServiceHubEnterprise.SoapApplications.Services;

/// <summary>
/// Singleton store for SOAP test cases, persisted to the SQLite database
/// via SoapDbContext. Test cases are attached to request files and define
/// extraction/assertion rules (XPath / JSON path / PDF) evaluated at execution time.
/// </summary>
public class SoapTestCaseStore
{
    private readonly IServiceProvider _serviceProvider;

    public SoapTestCaseStore(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }

    /// <summary>All test cases, ordered by application then file name.</summary>
    public IReadOnlyList<SoapTestCase> TestCases
    {
        get
        {
            using var scope = _serviceProvider.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();
            return db.SoapTestCases.AsNoTracking()
                .Include(t => t.Extractors)
                .OrderBy(t => t.AppName).ThenBy(t => t.FileName).ThenBy(t => t.Name)
                .AsEnumerable()
                .Select(MapTestCase)
                .ToList();
        }
    }

    /// <summary>Returns enabled test cases attached to a specific file.</summary>
    public IReadOnlyList<SoapTestCase> GetEnabledForFile(string appName, string fileName)
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();
        return db.SoapTestCases.AsNoTracking()
            .Include(t => t.Extractors)
            .Where(t => t.AppName == appName && t.FileName == fileName && t.Enabled)
            .AsEnumerable()
            .Select(MapTestCase)
            .ToList();
    }

    /// <summary>Returns all test cases attached to a specific file (any enabled state).</summary>
    public IReadOnlyList<SoapTestCase> GetForFile(string appName, string fileName)
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();
        return db.SoapTestCases.AsNoTracking()
            .Include(t => t.Extractors)
            .Where(t => t.AppName == appName && t.FileName == fileName)
            .AsEnumerable()
            .Select(MapTestCase)
            .ToList();
    }

    /// <summary>Returns a test case by id, or null.</summary>
    public SoapTestCase? GetTestCase(string id)
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();
        var entity = db.SoapTestCases.AsNoTracking()
            .Include(t => t.Extractors)
            .FirstOrDefault(t => t.Id == id);
        return entity is not null ? MapTestCase(entity) : null;
    }

    /// <summary>Adds a test case and persists to the database.</summary>
    public async Task AddTestCaseAsync(SoapTestCase testCase)
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();
        db.SoapTestCases.Add(MapToEntity(testCase));
        await db.SaveChangesAsync();
    }

    /// <summary>Updates an existing test case and persists.</summary>
    public async Task UpdateTestCaseAsync(SoapTestCase testCase)
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();
        var existing = await db.SoapTestCases
            .Include(t => t.Extractors)
            .FirstOrDefaultAsync(t => t.Id == testCase.Id);
        if (existing is null) return;

        existing.Name = testCase.Name;
        existing.Description = testCase.Description;
        existing.Enabled = testCase.Enabled;
        existing.UpdatedBy = testCase.UpdatedBy;
        existing.UpdatedAt = testCase.UpdatedAt;

        // Remove old extractors and re-add
        db.SoapExtractors.RemoveRange(existing.Extractors);
        existing.Extractors = testCase.Extractors.Select(e => new SoapExtractorEntity
        {
            Id = e.Id,
            TestCaseId = testCase.Id,
            Name = e.Name,
            Source = e.Source,
            Type = e.Type,
            Path = e.Path,
            ExpectedValue = e.ExpectedValue
        }).ToList();

        await db.SaveChangesAsync();
    }

    /// <summary>Removes a test case and persists.</summary>
    public async Task DeleteTestCaseAsync(string id)
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();
        var entity = await db.SoapTestCases.FindAsync(id);
        if (entity is not null)
        {
            db.SoapTestCases.Remove(entity);
            await db.SaveChangesAsync();
        }
    }

    /// <summary>Writes all test cases to the database (full replacement).</summary>
    public async Task PersistAllAsync(IReadOnlyList<SoapTestCase> testCases)
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();
        db.SoapTestCases.RemoveRange(db.SoapTestCases);
        foreach (var tc in testCases)
        {
            db.SoapTestCases.Add(MapToEntity(tc));
        }
        await db.SaveChangesAsync();
    }

    // ── Mapping helpers ──

    private static SoapTestCase MapTestCase(SoapTestCaseEntity entity)
    {
        return new SoapTestCase
        {
            Id = entity.Id,
            Name = entity.Name,
            Description = entity.Description,
            AppName = entity.AppName,
            FileName = entity.FileName,
            Enabled = entity.Enabled,
            CreatedBy = entity.CreatedBy,
            CreatedAt = entity.CreatedAt,
            UpdatedBy = entity.UpdatedBy,
            UpdatedAt = entity.UpdatedAt,
            Extractors = entity.Extractors.Select(e => new SoapExtractor
            {
                Id = e.Id,
                Name = e.Name,
                Source = e.Source,
                Type = e.Type,
                Path = e.Path,
                ExpectedValue = e.ExpectedValue
            }).ToList()
        };
    }

    private static SoapTestCaseEntity MapToEntity(SoapTestCase testCase)
    {
        return new SoapTestCaseEntity
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
            UpdatedAt = testCase.UpdatedAt,
            Extractors = testCase.Extractors.Select(e => new SoapExtractorEntity
            {
                Id = e.Id,
                TestCaseId = testCase.Id,
                Name = e.Name,
                Source = e.Source,
                Type = e.Type,
                Path = e.Path,
                ExpectedValue = e.ExpectedValue
            }).ToList()
        };
    }
}
