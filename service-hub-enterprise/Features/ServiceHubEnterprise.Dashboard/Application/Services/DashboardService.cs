using ServiceHubEnterprise.Dashboard.Application.DTOs;
using ServiceHubEnterprise.Dashboard.Core.Interfaces;

namespace ServiceHubEnterprise.Dashboard.Application.Services;

/// <summary>
/// Provides dashboard data by aggregating from the underlying repository.
/// </summary>
internal sealed class DashboardService : IDashboardService
{
    private readonly IDashboardRepository _repository;

    public DashboardService(IDashboardRepository repository)
    {
        _repository = repository;
    }

    /// <inheritdoc />
    public async Task<DashboardMetricsDto> GetMetricsAsync()
    {
        var entity = await _repository.GetMetricsAsync();

        return new DashboardMetricsDto
        {
            RestAppCount = entity.RestAppCount,
            RestAppsEnabled = entity.RestAppsEnabled,
            SoapAppCount = entity.SoapAppCount,
            SoapAppsEnabled = entity.SoapAppsEnabled,
            TestSuiteCount = entity.TestSuiteCount,
            PassingCases = entity.PassingCases,
            TotalCases = entity.TotalCases
        };
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<ServiceHealthDto>> GetServiceHealthAsync()
    {
        var entities = await _repository.GetServiceHealthAsync();

        return entities
            .Select(e => new ServiceHealthDto
            {
                Name = e.Name,
                Status = e.Status.ToString()
            })
            .ToList();
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<TestSuiteDto>> GetTestSuitesAsync()
    {
        var entities = await _repository.GetTestSuitesAsync();

        return entities
            .Select(e => new TestSuiteDto
            {
                Name = e.Name,
                TotalCases = e.TotalCases,
                PassingCases = e.PassingCases,
                TotalFiles = e.TotalFiles
            })
            .ToList();
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<RecentActivityDto>> GetRecentActivityAsync(int maxEntries = 10)
    {
        var entities = await _repository.GetRecentActivityAsync();

        return entities
            .Select(e => new RecentActivityDto
            {
                User = e.User,
                Action = e.Action,
                TimeAgo = e.TimeAgo
            })
            .Take(maxEntries)
            .ToList();
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<RequestFileDto>> GetRequestFilesAsync()
    {
        var entities = await _repository.GetRequestFilesAsync();

        return entities
            .Select(e => new RequestFileDto
            {
                FileName = e.FileName,
                AppName = e.AppName,
                Verb = e.Verb,
                Status = e.Status,
                CreatedBy = e.CreatedBy
            })
            .ToList();
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<WsdlRecordDto>> GetWsdlRecordsAsync()
    {
        var entities = await _repository.GetWsdlRecordsAsync();

        return entities
            .Select(e => new WsdlRecordDto
            {
                AppName = e.AppName,
                SourceType = e.SourceType,
                UploadedAt = e.UploadedAt,
                Status = e.Status,
                VersionCount = e.VersionCount
            })
            .ToList();
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<UserDto>> GetUsersAsync()
    {
        var entities = await _repository.GetUsersAsync();

        return entities
            .Select(e => new UserDto
            {
                Name = e.Name,
                Role = e.Role
            })
            .ToList();
    }

    /// <inheritdoc />
    public async Task<UserDto?> GetCurrentUserAsync()
    {
        var entity = await _repository.GetCurrentUserAsync();

        return entity is null
            ? null
            : new UserDto
            {
                Name = entity.Name,
                Role = entity.Role
            };
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<RestAppDto>> GetRestAppsAsync()
    {
        var entities = await _repository.GetRestAppsAsync();

        return entities
            .Select(e => new RestAppDto
            {
                Id = e.Id,
                Name = e.Name,
                BaseUrl = e.BaseUrl,
                Description = e.Description,
                Status = e.Status,
                CreatedBy = e.CreatedBy,
                CreatedAt = e.CreatedAt,
                UpdatedAt = e.UpdatedAt,
                ApisCount = e.ApisCount
            })
            .ToList();
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<SoapAppDto>> GetSoapAppsAsync()
    {
        var entities = await _repository.GetSoapAppsAsync();

        return entities
            .Select(e => new SoapAppDto
            {
                Id = e.Id,
                Name = e.Name,
                BaseUrl = e.BaseUrl,
                Description = e.Description,
                Status = e.Status,
                CreatedBy = e.CreatedBy,
                CreatedAt = e.CreatedAt,
                UpdatedAt = e.UpdatedAt,
                ApisCount = e.ApisCount
            })
            .ToList();
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<RequestFileDto>> GetRestRequestFilesAsync()
    {
        var entities = await _repository.GetRestRequestFilesAsync();

        return entities
            .Select(e => new RequestFileDto
            {
                FileName = e.FileName,
                AppName = e.AppName,
                Verb = e.Verb,
                Status = e.Status,
                CreatedBy = e.CreatedBy
            })
            .ToList();
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<UserActivityDto>> GetUserActivitiesAsync()
    {
        var entities = await _repository.GetUserActivitiesAsync();

        return entities
            .Select(e => new UserActivityDto
            {
                Id = e.Id,
                UserName = e.UserName,
                Action = e.Action,
                Timestamp = e.Timestamp
            })
            .ToList();
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<RequestExecutionDto>> GetRequestExecutionsAsync()
    {
        var entities = await _repository.GetRequestExecutionsAsync();

        return entities
            .Select(e => new RequestExecutionDto
            {
                Id = e.Id,
                AppName = e.AppName,
                AppType = e.AppType,
                FileName = e.FileName,
                Status = e.Status,
                ExecutedAt = e.ExecutedAt,
                DurationMs = e.DurationMs,
                TriggeredBy = e.TriggeredBy
            })
            .ToList();
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<TestSuiteHistoryDto>> GetTestSuiteHistoryAsync()
    {
        var entities = await _repository.GetTestSuiteHistoryAsync();

        return entities
            .Select(e => new TestSuiteHistoryDto
            {
                Id = e.Id,
                SuiteName = e.SuiteName,
                ExecutedAt = e.ExecutedAt,
                Status = e.Status,
                TotalCases = e.TotalCases,
                PassingCases = e.PassingCases,
                DurationMs = e.DurationMs
            })
            .ToList();
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<ServiceUptimeDto>> GetServiceUptimeAsync()
    {
        var entities = await _repository.GetServiceUptimeAsync();

        return entities
            .Select(e => new ServiceUptimeDto
            {
                Id = e.Id,
                ServiceName = e.ServiceName,
                Timestamp = e.Timestamp,
                Status = e.Status
            })
            .ToList();
    }
}
