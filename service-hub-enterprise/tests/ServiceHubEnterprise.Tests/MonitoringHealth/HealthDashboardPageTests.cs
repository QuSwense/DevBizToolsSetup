using ServiceHubEnterprise.MonitoringHealth.Pages;

namespace ServiceHubEnterprise.Tests.MonitoringHealth;

public class HealthDashboardPageTests : BunitTestBase
{
    [Fact]
    public void HealthDashboardRendersSummary()
    {
        var cut = Render<HealthDashboard>();

        cut.Markup.Should().Contain("Overall Health");
        cut.Markup.Should().Contain("3 / 5");
        cut.Markup.Should().Contain("Avg Response Time");
        cut.Markup.Should().Contain("Billing SOAP");
    }
}
