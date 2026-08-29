using LinqToDB;
using LinqToDB.Async;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using OrbitHub.Data.RestManagement;
using OrbitHub.Data.TestManagement;
using OrbitHub.Data.UserManagement;
using OrbitHub.Dashboard.Core.Entities;
using OrbitHub.Dashboard.Core.Interfaces;

// Import the Data contexts selectively to avoid entity-name collisions with the Dashboard entities.
using SoapDbContext = OrbitHub.Data.SoapManagement.SoapDbContext;
using WsdlDbContext = OrbitHub.Data.WsdlManagement.WsdlDbContext;

namespace OrbitHub.Dashboard.Infrastructure.Repositories;

/// <summary>
/// Reads dashboard data from the MSSQL database through the linq2db data connections.
/// Replaces the previous mock JSON loader; sections without a backing table return empty.
/// </summary>
internal sealed class DashboardRepository(IServiceProvider serviceProvider, IConfiguration configuration) : IDashboardRepository
{
    private readonly IServiceProvider _serviceProvider = serviceProvider;
    private readonly IConfiguration _configuration = configuration;

    /// <inheritdoc />
    public Task<IReadOnlyList<ServiceHealthEntity>> GetServiceHealthAsync()
    {
        // No service-health table exists in the schema yet.
        return Task.FromResult<IReadOnlyList<ServiceHealthEntity>>(Array.Empty<ServiceHealthEntity>());
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<TestSuiteEntity>> GetTestSuitesAsync()
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<TestDbContext>();

        var caseCountBySuite = (await db.ServiceTestSuitTestCaseLinks.ToListAsync())
            .ToLookup(l => l.ServiceTestSuiteId);

        return [.. (await db.ServiceTestSuites.ToListAsync())
            .Select(s => new TestSuiteEntity
            {
                Name = s.Name,
                TotalCases = caseCountBySuite[s.Id].Count(),
                PassingCases = 0, // no pass/fail tracking in the schema yet
                TotalFiles = 0
            })];
    }

    /// <inheritdoc />
    public async Task<DashboardMetricsEntity> GetMetricsAsync()
    {
        using var scope = _serviceProvider.CreateScope();
        var soap = scope.ServiceProvider.GetRequiredService<SoapDbContext>();
        var test = scope.ServiceProvider.GetRequiredService<TestDbContext>();

        var soapApps = await soap.SoapApps.ToListAsync();
        var testSuites = await test.ServiceTestSuites.ToListAsync();
        var testCases = await test.ServiceTestCases.ToListAsync();

        return new DashboardMetricsEntity
        {
            SoapAppCount = soapApps.Count,
            SoapAppsEnabled = soapApps.Count(a => a.Status.Equals("enabled", StringComparison.OrdinalIgnoreCase)),
            TestSuiteCount = testSuites.Count,
            TotalCases = testCases.Count,
            RestAppCount = 0,    // no REST-apps table in the schema yet
            RestAppsEnabled = 0, // no REST-apps table in the schema yet
            PassingCases = 0     // no pass/fail tracking in the schema yet
        };
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<RecentActivityEntity>> GetRecentActivityAsync()
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<UserDbContext>();

        return [.. (await db.UserActivities.OrderByDescending(a => a.Timestamp).ToListAsync())
            .Select(a => new RecentActivityEntity
            {
                User = a.UserId,
                Action = a.FeatureActivitiesJson ?? "",
                TimeAgo = a.Timestamp.ToString("yyyy-MM-dd HH:mm")
            })];
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<RequestFileEntity>> GetRequestFilesAsync()
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();

        return [.. (await db.SoapRequestFiles.ToListAsync())
            .Select(f => new RequestFileEntity
            {
                FileName = f.FileName,
                AppName = f.AppName,
                Verb = f.Verb,
                Status = f.Status,
                CreatedBy = f.CreatedBy
            })];
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<WsdlRecordEntity>> GetWsdlRecordsAsync()
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<WsdlDbContext>();

        var versionCountByRecord = (await db.WsdlVersions.ToListAsync())
            .ToLookup(v => v.SyncRecordId);

        return [.. (await db.WsdlRecords.ToListAsync())
            .Select(r => new WsdlRecordEntity
            {
                Id = r.Id,
                AppId = r.AppId,
                AppName = r.AppName,
                SourceType = r.SourceType,
                UploadedBy = r.UploadedBy,
                UploadedAt = r.UploadedAt,
                Status = r.Status,
                VersionCount = versionCountByRecord[r.Id].Count()
            })];
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<UserEntity>> GetUsersAsync()
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<UserDbContext>();

        return [.. (await db.Users.ToListAsync())
            .Select(u => new UserEntity
            {
                Name = FormatUserName(u),
                Role = u.Role ?? ""
            })];
    }

    /// <inheritdoc />
    public async Task<UserEntity?> GetCurrentUserAsync()
    {
        var currentUserName = _configuration["Users:CurrentUser"];

        if (string.IsNullOrWhiteSpace(currentUserName))
        {
            return null;
        }

        var users = await GetUsersAsync();
        return users.FirstOrDefault(u => u.Name.Equals(currentUserName, StringComparison.OrdinalIgnoreCase));
    }

    /// <inheritdoc />
    public Task<IReadOnlyList<RestAppEntity>> GetRestAppsAsync()
    {
        // No REST-apps table exists in the schema yet.
        return Task.FromResult<IReadOnlyList<RestAppEntity>>(Array.Empty<RestAppEntity>());
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<SoapAppEntity>> GetSoapAppsAsync()
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();

        var apiCountByApp = (await db.SoapApis.ToListAsync())
            .ToLookup(a => a.AppId);

        return [.. (await db.SoapApps.ToListAsync())
            .Select(a => new SoapAppEntity
            {
                Id = a.Id,
                Name = a.Name,
                BaseUrl = a.BaseUrl,
                Description = a.Description ?? "",
                Status = a.Status,
                CreatedBy = a.CreatedBy,
                CreatedAt = a.CreatedAt,
                UpdatedAt = a.UpdatedAt ?? "",
                ApisCount = apiCountByApp[a.Id].Count()
            })];
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<RequestFileEntity>> GetRestRequestFilesAsync()
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<RestDbContext>();

        return [.. (await db.RestRequestFiles.ToListAsync())
            .Select(f => new RequestFileEntity
            {
                FileName = f.FileName,
                AppName = f.AppName,
                Verb = f.Verb,
                Status = f.Status,
                CreatedBy = f.CreatedBy
            })];
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<UserActivityEntity>> GetUserActivitiesAsync()
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<UserDbContext>();

        return [.. (await db.UserActivities.OrderByDescending(a => a.Timestamp).ToListAsync())
            .Select(a => new UserActivityEntity
            {
                Id = a.Id.ToString(),
                UserName = a.UserId,
                Action = a.FeatureActivitiesJson ?? "",
                Timestamp = a.Timestamp.ToString("yyyy-MM-dd HH:mm:ss")
            })];
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<RequestExecutionEntity>> GetRequestExecutionsAsync()
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SoapDbContext>();

        var groups = await db.SoapExecutionGroups.ToListAsync();
        var files = await db.SoapExecutionFiles.ToListAsync();

        return [.. files
            .Select(f =>
            {
                var group = groups.FirstOrDefault(g => g.Id == f.GroupId);
                return new RequestExecutionEntity
                {
                    Id = f.Id,
                    AppName = f.AppName,
                    AppType = "SOAP",
                    FileName = f.FileName,
                    Status = f.Status,
                    ExecutedAt = group?.StartedAt ?? "",
                    DurationMs = (int)(group?.DurationMs ?? 0),
                    TriggeredBy = group?.TriggeredBy ?? ""
                };
            })
            .OrderByDescending(e => e.ExecutedAt)];
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<TestSuiteHistoryEntity>> GetTestSuiteHistoryAsync()
    {
        using var scope = _serviceProvider.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<TestDbContext>();

        var suites = await db.ServiceTestSuites.ToListAsync();
        var suiteById = suites.ToDictionary(s => s.Id);

        return [.. (await db.ServiceTestExecutionAudits.OrderByDescending(a => a.ExecutedAt).ToListAsync())
            .Select(a =>
            {
                suiteById.TryGetValue(a.ServiceTestSuiteId, out var suite);
                var durationMs = a.ExecutionCompletedAt is { } end
                    ? (int)(end - a.ExecutedAt).TotalMilliseconds
                    : 0;
                return new TestSuiteHistoryEntity
                {
                    Id = a.Id.ToString(),
                    SuiteName = suite?.Name ?? a.ServiceTestSuiteId.ToString(),
                    ExecutedAt = a.ExecutedAt.ToString("yyyy-MM-dd HH:mm:ss"),
                    Status = a.ExecutionStatus,
                    TotalCases = 0,    // no per-audit case counts in the schema yet
                    PassingCases = 0,  // no per-audit case counts in the schema yet
                    DurationMs = Math.Max(durationMs, 0)
                };
            })];
    }

    /// <inheritdoc />
    public Task<IReadOnlyList<ServiceUptimeEntity>> GetServiceUptimeAsync()
    {
        // No service-uptime table exists in the schema yet.
        return Task.FromResult<IReadOnlyList<ServiceUptimeEntity>>(Array.Empty<ServiceUptimeEntity>());
    }

    private static string FormatUserName(User user)
    {
        var fullName = string.Join(" ", new[] { user.FirstName, user.LastName }.Where(s => !string.IsNullOrWhiteSpace(s)));
        return string.IsNullOrWhiteSpace(fullName) ? user.UserId : fullName;
    }
}
