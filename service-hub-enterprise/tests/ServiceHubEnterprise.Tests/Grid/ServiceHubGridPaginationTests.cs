using Microsoft.AspNetCore.Components;
using ServiceHubEnterprise.Grid.Components;

namespace ServiceHubEnterprise.Tests.Grid;

public class ServiceHubGridPaginationTests : BunitTestBase
{
    private IRenderedComponent<ServiceHubGrid<GridItem>> RenderPaged(
        Action<ComponentParameterCollectionBuilder<ServiceHubGrid<GridItem>>>? extra = null)
        => Render<ServiceHubGrid<GridItem>>((ComponentParameterCollectionBuilder<ServiceHubGrid<GridItem>> p) =>
        {
            p.Add(x => x.Items, GridTestData.ManyItems);
            p.Add(x => x.Columns, GridTestData.Columns());
            p.Add(x => x.RowIdSelector, i => i.Id);
            p.Add(x => x.PageSize, 5);
            p.Add(x => x.EnablePagination, true);
            extra?.Invoke(p);
        });

    private static string Normalize(string text) =>
        string.Join(" ", text.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries));

    [Fact]
    public void SlicesRowsByPageSize()
    {
        var cut = RenderPaged();

        cut.FindAll("tbody tr").Should().HaveCount(5);
        Normalize(cut.Find(".pagination-info").TextContent).Should().Be("Showing 1 - 5 of 12");
    }

    [Fact]
    public void NextNavigatesToNextPage()
    {
        int? pageChanged = null;
        int? currentChanged = null;
        var cut = RenderPaged(p =>
        {
            p.Add(x => x.PageChanged, EventCallback.Factory.Create<int>(this, v => pageChanged = v));
            p.Add(x => x.CurrentPageChanged, EventCallback.Factory.Create<int>(this, v => currentChanged = v));
        });

        var next = cut.FindAll(".pagination-btn").First(b => b.TextContent.Contains("Next"));
        next.Click();

        cut.Instance.CurrentPage.Should().Be(2);
        pageChanged.Should().Be(2);
        currentChanged.Should().Be(2);
        cut.FindAll("tbody tr").Should().HaveCount(5);
        Normalize(cut.Find(".pagination-info").TextContent).Should().Be("Showing 6 - 10 of 12");
    }

    [Fact]
    public void PrevDisabledOnFirstPage()
    {
        var cut = RenderPaged();

        var prev = cut.FindAll(".pagination-btn").First(b => b.TextContent.Contains("Prev"));
        prev.HasAttribute("disabled").Should().BeTrue();
    }

    [Fact]
    public void NextDisabledOnLastPage()
    {
        var cut = RenderPaged(p => p.Add(x => x.CurrentPage, 3));

        var next = cut.FindAll(".pagination-btn").First(b => b.TextContent.Contains("Next"));
        next.HasAttribute("disabled").Should().BeTrue();
    }

    [Fact]
    public void RendersPageNumberButtons()
    {
        var cut = RenderPaged();

        cut.FindAll(".pagination-num").Select(b => b.TextContent.Trim())
            .Should().BeEquivalentTo("1", "2", "3");
        cut.FindAll(".pagination-num")[0].ClassList.Contains("is-current").Should().BeTrue();
    }

    [Fact]
    public void NumberButtonNavigatesToPage()
    {
        int? pageChanged = null;
        var cut = RenderPaged(p => p.Add(x => x.PageChanged, EventCallback.Factory.Create<int>(this, v => pageChanged = v)));

        cut.FindAll(".pagination-num")[1].Click();

        cut.Instance.CurrentPage.Should().Be(2);
        pageChanged.Should().Be(2);
    }

    [Fact]
    public void OmitsPaginationWhenSinglePage()
    {
        var cut = Render<ServiceHubGrid<GridItem>>(p => p
            .Add(x => x.Items, GridTestData.Items)
            .Add(x => x.Columns, GridTestData.Columns())
            .Add(x => x.PageSize, 5)
            .Add(x => x.EnablePagination, true));

        cut.FindAll(".pagination-footer").Should().BeEmpty();
        cut.FindAll("tbody tr").Should().HaveCount(5);
    }

    [Fact]
    public void IgnoresOutOfRangeNavigation()
    {
        var cut = RenderPaged(p => p.Add(x => x.CurrentPage, 3));

        // Clicking "Next" on the last page is a no-op.
        var next = cut.FindAll(".pagination-btn").First(b => b.TextContent.Contains("Next"));
        next.Click();

        cut.Instance.CurrentPage.Should().Be(3);
    }
}
