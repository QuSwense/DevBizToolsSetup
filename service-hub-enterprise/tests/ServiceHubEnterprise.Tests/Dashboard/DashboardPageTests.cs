using Microsoft.Extensions.DependencyInjection;
using ServiceHubEnterprise.Dashboard.Application.Services;
using ServiceHubEnterprise.Tests.TestDoubles;
using DashboardPage = ServiceHubEnterprise.Dashboard.UI.Pages.Dashboard;

namespace ServiceHubEnterprise.Tests.Dashboard;

public class DashboardPageTests : BunitTestBase
{
    [Fact]
    public void RendersAllSixSectionCardsWhenLoaded()
    {
        Services.AddSingleton<IDashboardService>(new FakeDashboardService());

        var cut = Render<DashboardPage>();
        cut.WaitForState(() => cut.FindAll(".section-card").Count == 6, TimeSpan.FromSeconds(5));

        var titles = cut.FindAll(".card-title").Select(t => t.TextContent.Trim());
        titles.Should().Contain("Users");
        titles.Should().Contain("Test Suites");
        titles.Should().Contain("Service Health");
        titles.Should().Contain("Recent Activity");
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
