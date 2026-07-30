using ServiceHubEnterprise.Dashboard.Application.DTOs;

namespace ServiceHubEnterprise.Dashboard.Application.Services;

/// <summary>
/// Provides dashboard data by aggregating from underlying feature services.
/// </summary>
internal sealed class DashboardService : IDashboardService
{
    /// <inheritdoc />
    public Task<DashboardMetricsDto> GetMetricsAsync()
    {
        // TODO: Aggregate real metrics from other feature services.
        var metrics = new DashboardMetricsDto
        {
            RestAppCount = 4,
            SoapAppCount = 2,
            TestSuiteCount = 4,
            RestAppsEnabled = 3,
            SoapAppsEnabled = 1,
            PassingCases = 25,
            TotalCases = 84
        };

        return Task.FromResult(metrics);
    }

    /// <inheritdoc />
    public Task<IReadOnlyList<RecentActivityDto>> GetRecentActivityAsync(int maxEntries = 10)
    {
        // TODO: Load from a real activity store.
        var activities = new List<RecentActivityDto>
        {
            new() { User = "Priya Sharma", Action = "created application PaymentService", TimeAgo = "2 hours ago" },
            new() { User = "Rahul Patel", Action = "executed Test Suite Smoke Suite and 12 files passed", TimeAgo = "2 hours ago" },
            new() { User = "Anita Desai", Action = "disabled application InventoryAPI", TimeAgo = "5 hours ago" },
            new() { User = "Vikram Singh", Action = "added 3 new APIs to OrderService", TimeAgo = "yesterday" },
            new() { User = "Suresh Kumar", Action = "imported WSDL for LegacyBilling and 3 operations synced", TimeAgo = "yesterday" },
            new() { User = "Priya Sharma", Action = "created template Payment Success Template", TimeAgo = "1 day ago" },
            new() { User = "System", Action = "detected Billing SOAP service down", TimeAgo = "2 hours ago" }
        };

        return Task.FromResult<IReadOnlyList<RecentActivityDto>>(
            activities.Take(maxEntries).ToList()
        );
    }
}
