using Microsoft.AspNetCore.Components;
using ServiceHubEnterprise.Grid.Components;

namespace ServiceHubEnterprise.Tests.Grid;

public class ServiceHubGridExpandTests : BunitTestBase
{
    private static RenderFragment<GridItem> DetailRow => item => b =>
        b.AddMarkupContent(0, $"<div class=\"detail\" data-id=\"{item.Id}\">details for {item.Id}</div>");

    private IRenderedComponent<ServiceHubGrid<GridItem>> RenderExpandable(
        Action<ComponentParameterCollectionBuilder<ServiceHubGrid<GridItem>>>? extra = null)
        => Render<ServiceHubGrid<GridItem>>((ComponentParameterCollectionBuilder<ServiceHubGrid<GridItem>> p) =>
        {
            p.Add(x => x.Items, GridTestData.Items);
            p.Add(x => x.Columns, GridTestData.Columns());
            p.Add(x => x.RowIdSelector, i => i.Id);
            p.Add(x => x.EnableExpand, true);
            p.Add(x => x.DetailRow, DetailRow);
            extra?.Invoke(p);
        });

    [Fact]
    public void ExpandButtonTogglesDetailRow()
    {
        var cut = RenderExpandable();

        cut.Find(".expand-btn").Click();
        cut.FindAll(".detail").Should().HaveCount(1);
        cut.Find(".detail").GetAttribute("data-id").Should().Be("r1");

        cut.Find(".expand-btn").Click();
        cut.FindAll(".detail").Should().BeEmpty();
    }

    [Fact]
    public async Task ExpandRowPublicMethodExpandsGivenRow()
    {
        var cut = RenderExpandable();

        await cut.InvokeAsync(() => cut.Instance.ExpandRow("r2"));

        cut.FindAll(".detail").Should().HaveCount(1);
        cut.Find(".detail").GetAttribute("data-id").Should().Be("r2");
    }

    [Fact]
    public async Task SetRowsExpandedExpandsThenCollapses()
    {
        var cut = RenderExpandable();

        await cut.InvokeAsync(() => cut.Instance.SetRowsExpanded(new[] { "r1", "r3" }, true));
        cut.FindAll(".detail").Should().HaveCount(2);

        await cut.InvokeAsync(() => cut.Instance.SetRowsExpanded(new[] { "r1", "r3" }, false));
        cut.FindAll(".detail").Should().BeEmpty();
    }

    [Fact]
    public void ExpandButtonChevronReflectsState()
    {
        var cut = RenderExpandable();

        cut.Find(".expand-btn i").ClassList.Contains("bi-chevron-down").Should().BeTrue();

        cut.Find(".expand-btn").Click();

        cut.Find(".expand-btn i").ClassList.Contains("bi-chevron-up").Should().BeTrue();
    }

    [Fact]
    public void DetailRowNotRenderedWhenNotExpanded()
    {
        var cut = RenderExpandable();

        cut.FindAll(".detail").Should().BeEmpty();
    }
}
