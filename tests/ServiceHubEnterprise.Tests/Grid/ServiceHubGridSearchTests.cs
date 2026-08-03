using Microsoft.AspNetCore.Components;
using ServiceHubEnterprise.Grid.Components;

namespace ServiceHubEnterprise.Tests.Grid;

public class ServiceHubGridSearchTests : BunitTestBase
{
    [Fact]
    public void TypingInSearchInvokesCallbacksAndResetsPage()
    {
        string? text = null;
        string? changed = null;
        int? page = null;
        var cut = Render<ServiceHubGrid<GridItem>>(p => p
            .Add(x => x.Items, GridTestData.ManyItems)
            .Add(x => x.Columns, GridTestData.Columns())
            .Add(x => x.RowIdSelector, i => i.Id)
            .Add(x => x.EnableSearch, true)
            .Add(x => x.CurrentPage, 3)
            .Add(x => x.SearchTextChanged, EventCallback.Factory.Create<string>(this, v => text = v))
            .Add(x => x.SearchChanged, EventCallback.Factory.Create<string>(this, v => changed = v))
            .Add(x => x.CurrentPageChanged, EventCallback.Factory.Create<int>(this, v => page = v)));

        cut.Find(".search-box input").Input("bob");

        text.Should().Be("bob");
        changed.Should().Be("bob");
        cut.Instance.SearchText.Should().Be("bob");
        cut.Instance.CurrentPage.Should().Be(1);
        page.Should().Be(1);
    }

    [Fact]
    public void SearchInputReflectsSearchText()
    {
        var cut = Render<ServiceHubGrid<GridItem>>(p => p
            .Add(x => x.Items, GridTestData.Items)
            .Add(x => x.Columns, GridTestData.Columns())
            .Add(x => x.EnableSearch, true)
            .Add(x => x.SearchText, "abc"));

        cut.Find(".search-box input").GetAttribute("value").Should().Be("abc");
        cut.Find(".search-box").ClassList.Contains("has-value").Should().BeTrue();
    }
}
