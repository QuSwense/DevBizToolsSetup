using Microsoft.AspNetCore.Components;
using ServiceHubEnterprise.Grid.Components;

namespace ServiceHubEnterprise.Tests.Grid;

public class ServiceHubGridSortTests : BunitTestBase
{
    [Fact]
    public void ClickingSortableHeaderInvokesSortColumnChanged()
    {
        string? col = null;
        bool asc = true;
        var cut = Render<ServiceHubGrid<GridItem>>(p => p
            .Add(x => x.Items, GridTestData.ManyItems)
            .Add(x => x.Columns, GridTestData.Columns())
            .Add(x => x.RowIdSelector, i => i.Id)
            .Add(x => x.SortColumnChanged, EventCallback.Factory.Create<string?>(this, v => col = v))
            .Add(x => x.SortAscendingChanged, EventCallback.Factory.Create<bool>(this, v => asc = v)));

        cut.FindAll("th.sortable")[0].Click();

        col.Should().Be("Name");
        asc.Should().BeTrue();
        cut.Instance.SortColumn.Should().Be("Name");
        cut.Instance.SortAscending.Should().BeTrue();
    }

    [Fact]
    public void ClickingSameHeaderTogglesAscending()
    {
        string? col = null;
        bool asc = true;
        var cut = Render<ServiceHubGrid<GridItem>>(p => p
            .Add(x => x.Items, GridTestData.ManyItems)
            .Add(x => x.Columns, GridTestData.Columns())
            .Add(x => x.RowIdSelector, i => i.Id)
            .Add(x => x.SortColumnChanged, EventCallback.Factory.Create<string?>(this, v => col = v))
            .Add(x => x.SortAscendingChanged, EventCallback.Factory.Create<bool>(this, v => asc = v)));

        cut.FindAll("th.sortable")[0].Click();
        cut.FindAll("th.sortable")[0].Click();

        col.Should().Be("Name");
        asc.Should().BeFalse();
        cut.Instance.SortAscending.Should().BeFalse();
    }

    [Fact]
    public void NonSortableColumnDoesNotSort()
    {
        string? col = null;
        var cut = Render<ServiceHubGrid<GridItem>>(p => p
            .Add(x => x.Items, GridTestData.ManyItems)
            .Add(x => x.Columns, GridTestData.Columns())
            .Add(x => x.RowIdSelector, i => i.Id)
            .Add(x => x.SortColumnChanged, EventCallback.Factory.Create<string?>(this, v => col = v)));

        cut.FindAll("th:not(.sortable)")[0].Click();

        col.Should().BeNull();
        cut.Instance.SortColumn.Should().BeNull();
    }

    [Fact]
    public void SortableHeaderShowsSortIndicator()
    {
        var cut = Render<ServiceHubGrid<GridItem>>(p => p
            .Add(x => x.Items, GridTestData.ManyItems)
            .Add(x => x.Columns, GridTestData.Columns())
            .Add(x => x.RowIdSelector, i => i.Id));

        cut.FindAll("th.sortable")[0].Click();

        var indicator = cut.FindAll("th.sortable")[0].QuerySelector(".sort-indicator i");
        indicator.Should().NotBeNull();
        indicator!.ClassList.Contains("bi-chevron-up").Should().BeTrue();
    }

    [Fact]
    public void SortingResetsToFirstPage()
    {
        int? page = null;
        var cut = Render<ServiceHubGrid<GridItem>>(p => p
            .Add(x => x.Items, GridTestData.ManyItems)
            .Add(x => x.Columns, GridTestData.Columns())
            .Add(x => x.RowIdSelector, i => i.Id)
            .Add(x => x.PageSize, 5)
            .Add(x => x.EnablePagination, true)
            .Add(x => x.CurrentPage, 2)
            .Add(x => x.PageChanged, EventCallback.Factory.Create<int>(this, v => page = v)));

        cut.FindAll("th.sortable")[0].Click();

        page.Should().Be(1);
        cut.Instance.CurrentPage.Should().Be(1);
    }
}
