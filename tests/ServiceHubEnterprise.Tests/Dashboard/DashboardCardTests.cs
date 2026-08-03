using Microsoft.AspNetCore.Components;
using ServiceHubEnterprise.Dashboard.Application.DTOs;
using ServiceHubEnterprise.Dashboard.UI.Components;

namespace ServiceHubEnterprise.Tests.Dashboard;

public class DashboardCardTests : BunitTestBase
{
    private static string TileValue<T>(IRenderedComponent<T> cut, string label) where T : IComponent
    {
        var tile = cut.FindAll(".kpi-tile")
            .First(t => t.QuerySelector(".kpi-title")!.TextContent.Trim() == label);
        return tile.QuerySelector(".kpi-value")!.TextContent.Trim();
    }

    [Fact]
    public void UsersOverviewComputesStats()
    {
        var today = DateTime.Today;
        var cut = Render<UsersOverview>(p => p
            .Add(x => x.Users, new[]
            {
                new UserDto { Name = "Priya Sharma", Role = "Superuser" },
                new UserDto { Name = "Rahul Verma", Role = "User" }
            })
            .Add(x => x.Activities, new[]
            {
                new UserActivityDto { UserName = "Priya Sharma", Action = "added", Timestamp = today.AddHours(-1).ToString("yyyy-MM-dd HH:mm:ss") },
                new UserActivityDto { UserName = "Rahul Verma", Action = "ran", Timestamp = today.AddDays(-2).ToString("yyyy-MM-dd HH:mm:ss") },
                new UserActivityDto { UserName = "Old User", Action = "old", Timestamp = today.AddDays(-30).ToString("yyyy-MM-dd HH:mm:ss") }
            }));

        TileValue(cut, "Total Users").Should().Be("2");
        TileValue(cut, "User Types").Should().Be("2");
        TileValue(cut, "Active in Range").Should().Be("2"); // Old User excluded by the 7-day range
        cut.FindAll(".top-user-name").Should().HaveCount(2);
    }

    [Fact]
    public void ServiceHealthOverviewComputesStatusCounts()
    {
        var today = DateTime.Today;
        var cut = Render<ServiceHealthOverview>(p => p
            .Add(x => x.Services, new[]
            {
                new ServiceHealthDto { Name = "API Gateway", Status = "ok" },
                new ServiceHealthDto { Name = "Auth", Status = "degraded" },
                new ServiceHealthDto { Name = "Database", Status = "down" }
            })
            .Add(x => x.Uptime, new[]
            {
                new ServiceUptimeDto { ServiceName = "API Gateway", Status = "ok", Timestamp = today.AddDays(-1).ToString("yyyy-MM-dd HH:mm:ss") },
                new ServiceUptimeDto { ServiceName = "API Gateway", Status = "ok", Timestamp = today.ToString("yyyy-MM-dd HH:mm:ss") },
                new ServiceUptimeDto { ServiceName = "Auth", Status = "degraded", Timestamp = today.ToString("yyyy-MM-dd HH:mm:ss") }
            }));

        TileValue(cut, "Services").Should().Be("3");
        TileValue(cut, "Operational").Should().Be("1");
        TileValue(cut, "Degraded").Should().Be("1");
        TileValue(cut, "Down").Should().Be("1");

        // API Gateway: 2/2 ok samples → 100% uptime in range.
        var gwRow = cut.FindAll(".health-row").First(r => r.TextContent.Contains("API Gateway"));
        gwRow.QuerySelector(".health-up")!.TextContent.Trim().Should().Be("100%");
    }

    [Fact]
    public void ServiceHealthOverviewShowsEmptyState()
    {
        var cut = Render<ServiceHealthOverview>(p => p.Add(x => x.Services, Array.Empty<ServiceHealthDto>()));

        cut.Markup.Should().Contain("No services configured.");
    }

    [Fact]
    public void TestSuitesOverviewComputesTotals()
    {
        var cut = Render<TestSuitesOverview>(p => p
            .Add(x => x.Suites, new[]
            {
                new TestSuiteDto { Name = "Smoke", TotalCases = 10, PassingCases = 10 },
                new TestSuiteDto { Name = "Regression", TotalCases = 20, PassingCases = 15 }
            })
            .Add(x => x.History, Array.Empty<TestSuiteHistoryDto>()));

        TileValue(cut, "Total Suites").Should().Be("2");
        TileValue(cut, "Total Cases").Should().Be("30");
        TileValue(cut, "Passing").Should().Be("25");
    }

    [Fact]
    public void RecentActivityFiltersToRange()
    {
        var cut = Render<RecentActivity>(p => p
            .Add(x => x.Activities, new[]
            {
                new RecentActivity.ActivityEntry("Priya", "added app", DateTime.Today.AddHours(-1)),
                new RecentActivity.ActivityEntry("Rahul", "ran suite", DateTime.Today.AddDays(-2)),
                new RecentActivity.ActivityEntry("Old User", "old event", DateTime.Today.AddDays(-30))
            })
            .Add(x => x.Users, new[] { "Priya", "Rahul" })
            .Add(x => x.MaxItems, 10));

        // The 30-day-old entry is outside the default 7-day range.
        cut.FindAll(".activity-item").Should().HaveCount(2);
        cut.Markup.Should().Contain("added app");
    }

    [Fact]
    public void RecentActivityFiltersByUser()
    {
        var cut = Render<RecentActivity>(p => p
            .Add(x => x.Activities, new[]
            {
                new RecentActivity.ActivityEntry("Priya", "added app", DateTime.Today.AddHours(-1)),
                new RecentActivity.ActivityEntry("Rahul", "ran suite", DateTime.Today.AddDays(-2))
            })
            .Add(x => x.Users, new[] { "Priya", "Rahul" }));

        cut.Find(".user-select").Change("Priya");
        cut.WaitForAssertion(() => cut.FindAll(".activity-item").Should().HaveCount(1));

        cut.Markup.Should().Contain("added app");
        cut.Markup.Should().NotContain("ran suite");
    }
}
