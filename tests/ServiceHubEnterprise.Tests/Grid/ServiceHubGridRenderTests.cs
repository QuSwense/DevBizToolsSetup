using Microsoft.AspNetCore.Components;
using ServiceHubEnterprise.Grid.Components;

namespace ServiceHubEnterprise.Tests.Grid;

public class ServiceHubGridRenderTests : BunitTestBase
{
    private static RenderFragment<GridItem> RowActions => item => b =>
        b.AddMarkupContent(0, $"<button class=\"row-act\" data-id=\"{item.Id}\">act</button>");

    private static RenderFragment<GridItem> DetailRow => item => b =>
        b.AddMarkupContent(0, $"<div class=\"detail\" data-id=\"{item.Id}\">details</div>");

    [Fact]
    public void RendersColumnHeaders()
    {
        var cut = Render<ServiceHubGrid<GridItem>>(p => p
            .Add(x => x.Items, GridTestData.Items)
            .Add(x => x.Columns, GridTestData.Columns()));

        var headers = cut.FindAll("thead th").Select(h => h.TextContent.Trim());
        headers.Should().BeEquivalentTo("Name", "Age", "City");
    }

    [Fact]
    public void RendersAllRowsWhenNoPagination()
    {
        var cut = Render<ServiceHubGrid<GridItem>>(p => p
            .Add(x => x.Items, GridTestData.Items)
            .Add(x => x.Columns, GridTestData.Columns()));

        cut.FindAll("tbody tr").Should().HaveCount(GridTestData.Items.Length);
    }

    [Fact]
    public void SetsRowDataIdFromRowIdSelector()
    {
        var cut = Render<ServiceHubGrid<GridItem>>(p => p
            .Add(x => x.Items, GridTestData.Items)
            .Add(x => x.Columns, GridTestData.Columns())
            .Add(x => x.RowIdSelector, i => i.Id));

        cut.Find("tbody tr").GetAttribute("data-row-id").Should().Be("r1");
    }

    [Fact]
    public void RendersEmptyStateWhenNoItems()
    {
        var cut = Render<ServiceHubGrid<GridItem>>(p => p
            .Add(x => x.Items, Array.Empty<GridItem>())
            .Add(x => x.Columns, GridTestData.Columns())
            .Add(x => x.EmptyText, "Nothing here"));

        cut.Find("tbody td").TextContent.Should().Be("Nothing here");
        cut.Find("tbody td").GetAttribute("colspan").Should().Be("3");
    }

    [Fact]
    public void RendersRecordCountPill()
    {
        var cut = Render<ServiceHubGrid<GridItem>>(p => p
            .Add(x => x.Items, GridTestData.Items)
            .Add(x => x.Columns, GridTestData.Columns()));

        cut.FindAll(".meta-pill").First().TextContent.Trim().Should().Be("5 records");
    }

    [Fact]
    public void RendersSearchWhenEnabledAndOmitsWhenDisabled()
    {
        var withSearch = Render<ServiceHubGrid<GridItem>>(p => p
            .Add(x => x.Items, GridTestData.Items)
            .Add(x => x.Columns, GridTestData.Columns())
            .Add(x => x.EnableSearch, true)
            .Add(x => x.SearchPlaceholder, "Find..."));

        withSearch.FindAll(".search-box input").Should().HaveCount(1);
        withSearch.Find(".search-box input").GetAttribute("placeholder").Should().Be("Find...");

        var without = Render<ServiceHubGrid<GridItem>>(p => p
            .Add(x => x.Items, GridTestData.Items)
            .Add(x => x.Columns, GridTestData.Columns()));

        without.FindAll(".search-box").Should().BeEmpty();
    }

    [Fact]
    public void RendersActionsColumnWhenRowActionsProvided()
    {
        var cut = Render<ServiceHubGrid<GridItem>>(p => p
            .Add(x => x.Items, GridTestData.Items)
            .Add(x => x.Columns, GridTestData.Columns())
            .Add(x => x.RowActions, RowActions));

        cut.FindAll("thead th").Any(h => h.TextContent.Trim() == "Actions").Should().BeTrue();
        cut.FindAll("tbody .row-act").Should().HaveCount(GridTestData.Items.Length);
    }

    [Fact]
    public void RendersDetailRowWhenExpanded()
    {
        var cut = Render<ServiceHubGrid<GridItem>>(p => p
            .Add(x => x.Items, GridTestData.Items)
            .Add(x => x.Columns, GridTestData.Columns())
            .Add(x => x.EnableExpand, true)
            .Add(x => x.DetailRow, DetailRow));

        cut.FindAll(".detail").Should().BeEmpty();

        cut.Find(".expand-btn").Click();

        cut.FindAll(".detail").Should().HaveCount(1);
        cut.Find(".detail").GetAttribute("data-id").Should().Be("r1");
    }

    [Fact]
    public void RendersContextMenuFlagsWhenEnabled()
    {
        var cut = Render<ServiceHubGrid<GridItem>>(p => p
            .Add(x => x.Items, GridTestData.Items)
            .Add(x => x.Columns, GridTestData.Columns())
            .Add(x => x.EnableContextMenu, true));

        cut.Find(".datagrid-card").GetAttribute("data-blazor-context-menu").Should().Be("true");
        cut.Find("tbody tr").ClassList.Contains("has-context-menu").Should().BeTrue();
    }

    [Fact]
    public void CapturesAdditionalAttributesOnRoot()
    {
        var cut = Render<ServiceHubGrid<GridItem>>(p => p
            .Add(x => x.Items, GridTestData.Items)
            .Add(x => x.Columns, GridTestData.Columns())
            .AddUnmatched("data-custom", "hello"));

        cut.Find(".datagrid-card").GetAttribute("data-custom").Should().Be("hello");
    }
}
