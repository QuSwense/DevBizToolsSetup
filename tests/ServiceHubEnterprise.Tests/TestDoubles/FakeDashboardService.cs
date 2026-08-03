using ServiceHubEnterprise.Dashboard.Application.DTOs;
using ServiceHubEnterprise.Dashboard.Application.Services;

namespace ServiceHubEnterprise.Tests.TestDoubles;

/// <summary>
/// A hand-rolled IDashboardService fake with settable collections (empty by default).
/// Set <see cref="LoadException"/> to make every method return a faulted task.
/// </summary>
public sealed class FakeDashboardService : IDashboardService
{
    public DashboardMetricsDto? Metrics { get; set; } = new();
    public IReadOnlyList<ServiceHealthDto> HealthServices { get; set; } = [];
    public IReadOnlyList<TestSuiteDto> TestSuites { get; set; } = [];
    public IReadOnlyList<RecentActivityDto> RecentActivities { get; set; } = [];
    public IReadOnlyList<RequestFileDto> RequestFiles { get; set; } = [];
    public IReadOnlyList<WsdlRecordDto> WsdlRecords { get; set; } = [];
    public IReadOnlyList<UserDto> Users { get; set; } = [];
    public UserDto? CurrentUser { get; set; }
    public IReadOnlyList<RestAppDto> RestApps { get; set; } = [];
    public IReadOnlyList<SoapAppDto> SoapApps { get; set; } = [];
    public IReadOnlyList<RequestFileDto> RestRequestFiles { get; set; } = [];
    public IReadOnlyList<UserActivityDto> UserActivities { get; set; } = [];
    public IReadOnlyList<RequestExecutionDto> RequestExecutions { get; set; } = [];
    public IReadOnlyList<TestSuiteHistoryDto> TestSuiteHistory { get; set; } = [];
    public IReadOnlyList<ServiceUptimeDto> ServiceUptime { get; set; } = [];

    public Exception? LoadException { get; set; }

    private Task<T> Result<T>(T value) =>
        LoadException is null ? Task.FromResult(value) : Task.FromException<T>(LoadException);

    public Task<DashboardMetricsDto> GetMetricsAsync() => Result(Metrics!);
    public Task<IReadOnlyList<ServiceHealthDto>> GetServiceHealthAsync() => Result(HealthServices);
    public Task<IReadOnlyList<TestSuiteDto>> GetTestSuitesAsync() => Result(TestSuites);
    public Task<IReadOnlyList<RecentActivityDto>> GetRecentActivityAsync(int maxEntries = 10) =>
        Result((IReadOnlyList<RecentActivityDto>)RecentActivities.Take(maxEntries).ToList());
    public Task<IReadOnlyList<RequestFileDto>> GetRequestFilesAsync() => Result(RequestFiles);
    public Task<IReadOnlyList<WsdlRecordDto>> GetWsdlRecordsAsync() => Result(WsdlRecords);
    public Task<IReadOnlyList<UserDto>> GetUsersAsync() => Result(Users);
    public Task<UserDto?> GetCurrentUserAsync() => Result(CurrentUser);
    public Task<IReadOnlyList<RestAppDto>> GetRestAppsAsync() => Result(RestApps);
    public Task<IReadOnlyList<SoapAppDto>> GetSoapAppsAsync() => Result(SoapApps);
    public Task<IReadOnlyList<RequestFileDto>> GetRestRequestFilesAsync() => Result(RestRequestFiles);
    public Task<IReadOnlyList<UserActivityDto>> GetUserActivitiesAsync() => Result(UserActivities);
    public Task<IReadOnlyList<RequestExecutionDto>> GetRequestExecutionsAsync() => Result(RequestExecutions);
    public Task<IReadOnlyList<TestSuiteHistoryDto>> GetTestSuiteHistoryAsync() => Result(TestSuiteHistory);
    public Task<IReadOnlyList<ServiceUptimeDto>> GetServiceUptimeAsync() => Result(ServiceUptime);
}
