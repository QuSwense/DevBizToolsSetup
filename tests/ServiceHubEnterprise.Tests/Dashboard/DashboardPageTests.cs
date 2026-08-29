using Microsoft.Extensions.DependencyInjection;
using ServiceHubEnterprise.Dashboard.Application.Services;
using ServiceHubEnterprise.Tests.TestDoubles;
using DashboardPage = ServiceHubEnterprise.Dashboard.UI.Pages.Dashboard;

namespace ServiceHubEnterprise.Tests.Dashboard;

public class DashboardPageTests : BunitTestBase
{
    [Fact]
    public void RendersExecutiveHomeDashboardOverview()
    {
        Services.AddSingleton<IDashboardService>(new FakeDashboardService());

        var cut = Render<DashboardPage>();
        cut.WaitForState(() => cut.Markup.Contains("Home Dashboard"), TimeSpan.FromSeconds(5));

        cut.Markup.Should().Contain("Home Dashboard");
        cut.Markup.Should().Contain("Total Registered Applications");
        cut.Markup.Should().Contain("Usage Trend Graph");
        cut.Markup.Should().Contain("Service Health Snapshot");
        cut.Markup.Should().Contain("Recent Activities");
    }

    [Fact]
    public void ShowsErrorStateWhenServiceFails()
    {
        var fake = new FakeDashboardService { LoadException = new InvalidOperationException("boom") };
        Services.AddSingleton<IDashboardService>(fake);

        var cut = Render<DashboardPage>();
        cut.WaitForState(() => cut.FindAll(".alert-danger").Count > 0, TimeSpan.FromSeconds(5));

        cut.Markup.Should().Contain("Failed to load dashboard");
    }
}
