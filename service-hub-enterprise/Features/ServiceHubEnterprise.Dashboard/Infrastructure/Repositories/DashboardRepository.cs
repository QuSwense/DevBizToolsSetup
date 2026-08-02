using System.Text.Json;
using Microsoft.Extensions.Configuration;
using ServiceHubEnterprise.Dashboard.Core.Entities;
using ServiceHubEnterprise.Dashboard.Core.Interfaces;

namespace ServiceHubEnterprise.Dashboard.Infrastructure.Repositories;

/// <summary>
/// Reads dashboard data from mock_db JSON files.
/// Follows the same pattern as SoapApplications' MockDbLoader.
/// </summary>
internal sealed class DashboardRepository : IDashboardRepository
{
    private readonly string _mockDbPath;
    private readonly IConfiguration _configuration;
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public DashboardRepository(IConfiguration configuration)
    {
        _configuration = configuration;

        var configPath = configuration["MockDb:Path"]
            ?? throw new InvalidOperationException("MockDb:Path is not configured in appsettings.json.");

        _mockDbPath = Path.GetFullPath(Path.Combine(Directory.GetCurrentDirectory(), configPath));

        if (!Directory.Exists(_mockDbPath))
        {
            throw new DirectoryNotFoundException($"MockDb directory not found: {_mockDbPath}");
        }
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<ServiceHealthEntity>> GetServiceHealthAsync()
    {
        return await LoadJsonAsync<ServiceHealthEntity[]>("Dashboard/dashboard-health.json")
               ?? Array.Empty<ServiceHealthEntity>();
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<TestSuiteEntity>> GetTestSuitesAsync()
    {
        return await LoadJsonAsync<TestSuiteEntity[]>("Dashboard/dashboard-test-suites.json")
               ?? Array.Empty<TestSuiteEntity>();
    }

    /// <inheritdoc />
    public async Task<DashboardMetricsEntity> GetMetricsAsync()
    {
        return await LoadJsonAsync<DashboardMetricsEntity>("Dashboard/dashboard-metrics.json")
               ?? new DashboardMetricsEntity();
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<RecentActivityEntity>> GetRecentActivityAsync()
    {
        return await LoadJsonAsync<RecentActivityEntity[]>("Dashboard/dashboard-recent-activity.json")
               ?? Array.Empty<RecentActivityEntity>();
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<RequestFileEntity>> GetRequestFilesAsync()
    {
        return await LoadJsonAsync<RequestFileEntity[]>("Soap/Request/request-files.json")
               ?? Array.Empty<RequestFileEntity>();
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<WsdlRecordEntity>> GetWsdlRecordsAsync()
    {
        return await LoadJsonAsync<WsdlRecordEntity[]>("Wsdl/wsdl-records.json")
               ?? Array.Empty<WsdlRecordEntity>();
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<UserEntity>> GetUsersAsync()
    {
        return await LoadJsonAsync<UserEntity[]>("Dashboard/users.json")
               ?? Array.Empty<UserEntity>();
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
    public async Task<IReadOnlyList<RestAppEntity>> GetRestAppsAsync()
    {
        return await LoadJsonAsync<RestAppEntity[]>("Rest/rest-apps.json")
               ?? Array.Empty<RestAppEntity>();
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<SoapAppEntity>> GetSoapAppsAsync()
    {
        return await LoadJsonAsync<SoapAppEntity[]>("Soap/soap-apps.json")
               ?? Array.Empty<SoapAppEntity>();
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<RequestFileEntity>> GetRestRequestFilesAsync()
    {
        return await LoadJsonAsync<RequestFileEntity[]>("Rest/rest-request-files.json")
               ?? Array.Empty<RequestFileEntity>();
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<UserActivityEntity>> GetUserActivitiesAsync()
    {
        return await LoadJsonAsync<UserActivityEntity[]>("Dashboard/user-activity.json")
               ?? Array.Empty<UserActivityEntity>();
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<RequestExecutionEntity>> GetRequestExecutionsAsync()
    {
        return await LoadJsonAsync<RequestExecutionEntity[]>("Soap/Request/request-executions.json")
               ?? Array.Empty<RequestExecutionEntity>();
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<TestSuiteHistoryEntity>> GetTestSuiteHistoryAsync()
    {
        return await LoadJsonAsync<TestSuiteHistoryEntity[]>("Dashboard/test-suite-history.json")
               ?? Array.Empty<TestSuiteHistoryEntity>();
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<ServiceUptimeEntity>> GetServiceUptimeAsync()
    {
        return await LoadJsonAsync<ServiceUptimeEntity[]>("Dashboard/service-uptime.json")
               ?? Array.Empty<ServiceUptimeEntity>();
    }

    private async Task<T?> LoadJsonAsync<T>(string fileName) where T : class
    {
        var filePath = Path.Combine(_mockDbPath, fileName);

        if (!File.Exists(filePath))
        {
            return null;
        }

        await using var stream = File.OpenRead(filePath);
        return await JsonSerializer.DeserializeAsync<T>(stream, JsonOptions);
    }
}
