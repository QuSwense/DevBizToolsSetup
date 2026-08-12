using Microsoft.AspNetCore.Components;
using ServiceHubEnterprise.SoapApplications.Components;
using ServiceHubEnterprise.SoapApplications.Core.Enums;
using ServiceHubEnterprise.SoapApplications.Models;
using ServiceHubEnterprise.Tests.Builders;

namespace ServiceHubEnterprise.Tests.SoapApplications;

public class OverviewCardsTests : BunitTestBase
{
    private static string TileValue<T>(IRenderedComponent<T> cut, string label) where T : IComponent
    {
        var tile = cut.FindAll(".kpi-tile")
            .First(t => t.QuerySelector(".kpi-title")!.TextContent.Trim() == label);
        return tile.QuerySelector(".kpi-value")!.TextContent.Trim();
    }

    [Fact]
    public void ApplicationsOverviewComputesTotals()
    {
        var cut = Render<ApplicationsOverview>(p => p.Add(x => x.Apps, new[]
        {
            TestData.SoapApp(id: "1", status: AppStatus.Enabled, apis: [TestData.Api("GetInvoice")]),
            TestData.SoapApp(id: "2", status: AppStatus.Enabled, apis: [TestData.Api("A"), TestData.Api("B")]),
            TestData.SoapApp(id: "3", status: AppStatus.Disabled, apis: Array.Empty<SoapApiEntry>())
        }));

        TileValue(cut, "Total Apps").Should().Be("3");
        TileValue(cut, "Enabled").Should().Be("2");
        TileValue(cut, "Disabled").Should().Be("1");
        TileValue(cut, "Operations").Should().Be("3");
    }

    [Fact]
    public void ExecutionsOverviewFiltersToRangeAndAverages()
    {
        var today = DateTime.Today;
        var cut = Render<ExecutionsOverview>(p => p.Add(x => x.Executions, new[]
        {
            TestData.Execution(id: "e1", status: "success", executedAt: today.AddDays(-1).ToString("yyyy-MM-dd HH:mm:ss"), durationMs: 1000),
            TestData.Execution(id: "e2", status: "success", executedAt: today.ToString("yyyy-MM-dd HH:mm:ss"), durationMs: 2000),
            TestData.Execution(id: "e3", status: "failed", executedAt: today.AddDays(-30).ToString("yyyy-MM-dd HH:mm:ss"), durationMs: 500)
        }));

        // Default range is last 7 days → e1/e2 in range, e3 excluded.
        TileValue(cut, "Executions").Should().Be("2");
        TileValue(cut, "Success").Should().Be("2");
        TileValue(cut, "Failed").Should().Be("0");
        // (1000+2000)/2 = 1500ms → formatted with the current culture decimal separator.
        TileValue(cut, "Avg Duration").Should().MatchRegex(@"^1[.,]5s$");
    }

    [Fact]
    public void RequestFilesOverviewComputesStatusTotals()
    {
        var today = DateTime.Today;
        var cut = Render<RequestFilesOverview>(p => p.Add(x => x.Files, new[]
        {
            new SoapRequestFile("a.xml", "Billing", "op", "GET", "", "active", "Priya", today.AddDays(-1), "Priya", today.AddDays(-1)),
            new SoapRequestFile("b.xml", "Billing", "op", "POST", "", "inactive", "Priya", today.AddDays(-2), null, null),
            new SoapRequestFile("c.xml", "Orders", "op", "GET", "", "active", "Priya", today.AddDays(-30), "Priya", today.AddDays(-30))
        }));

        TileValue(cut, "Total Files").Should().Be("3");
        TileValue(cut, "Active").Should().Be("2");
        TileValue(cut, "Inactive").Should().Be("1");
        TileValue(cut, "Applications").Should().Be("2");
    }

    [Fact]
    public void TemplatesOverviewComputesExtendingAndUsage()
    {
        var cut = Render<TemplatesOverview>(p => p.Add(x => x.Templates, new[]
        {
            TestData.Template(id: "t1", name: "Base", variables: ["a"]),
            TestData.Template(id: "t2", name: "Child", extendsTemplateId: "t1", variables: ["a", "b"])
        }));

        TileValue(cut, "Templates").Should().Be("2");
        TileValue(cut, "Extending").Should().Be("1");
        TileValue(cut, "Variables").Should().Be("3");
        TileValue(cut, "Usage").Should().Be("3");
    }

    [Fact]
    public void WsdlSyncOverviewComputesStatusCounts()
    {
        var cut = Render<WsdlSyncOverview>(p => p
            .Add(x => x.Records, new[]
            {
                TestData.WsdlRecord(id: "r1", status: "synced"),
                TestData.WsdlRecord(id: "r2", status: "failed")
            })
            .Add(x => x.Versions, new[] { TestData.WsdlVersion() })
            .Add(x => x.SyncHistory, Array.Empty<WsdlSyncHistoryPoint>()));

        TileValue(cut, "Records").Should().Be("2");
        TileValue(cut, "Synced").Should().Be("1");
        TileValue(cut, "Failed").Should().Be("1");
        TileValue(cut, "Parsing").Should().Be("0");
        TileValue(cut, "Versions").Should().Be("1");
    }
}
