using Microsoft.AspNetCore.Components;
using ServiceHubEnterprise.Grid.Components;

namespace ServiceHubEnterprise.Tests.Grid;

public class ServiceHubGridFilterModalTests : BunitTestBase
{
    private static RenderFragment FilterBody => b =>
        b.AddMarkupContent(0, "<input class=\"filter-field\" placeholder=\"name\" />");

    private IRenderedComponent<ServiceHubGrid<GridItem>> RenderModal(
        Action<ComponentParameterCollectionBuilder<ServiceHubGrid<GridItem>>>? extra = null)
        => Render<ServiceHubGrid<GridItem>>((ComponentParameterCollectionBuilder<ServiceHubGrid<GridItem>> p) =>
        {
            p.Add(x => x.Items, GridTestData.ManyItems);
            p.Add(x => x.Columns, GridTestData.Columns());
            p.Add(x => x.RowIdSelector, i => i.Id);
            p.Add(x => x.PageSize, 5);
            p.Add(x => x.EnablePagination, true);
            p.Add(x => x.ShowFilterModal, true);
            p.Add(x => x.FilterModalTitle, "Filter Items");
            p.Add(x => x.FilterModalBody, FilterBody);
            extra?.Invoke(p);
        });

    [Fact]
    public void RendersModalWithBodyAndTitle()
    {
        var cut = RenderModal();

        cut.Find(".modal-overlay").Should().NotBeNull();
        cut.Find(".modal-header-dg h3").TextContent.Should().Be("Filter Items");
        cut.FindAll(".filter-field").Should().HaveCount(1);
    }

    [Fact]
    public void DoesNotRenderModalWhenHidden()
    {
        var cut = Render<ServiceHubGrid<GridItem>>(p => p
            .Add(x => x.Items, GridTestData.Items)
            .Add(x => x.Columns, GridTestData.Columns()));

        cut.FindAll(".modal-overlay").Should().BeEmpty();
    }

    [Fact]
    public void ApplyInvokesFilterAppliedClosesAndResetsPage()
    {
        bool applied = false;
        int? page = null;
        bool? shown = null;
        var cut = RenderModal(p =>
        {
            p.Add(x => x.CurrentPage, 2);
            p.Add(x => x.FilterApplied, EventCallback.Factory.Create(this, () => applied = true));
            p.Add(x => x.CurrentPageChanged, EventCallback.Factory.Create<int>(this, v => page = v));
            p.Add(x => x.ShowFilterModalChanged, EventCallback.Factory.Create<bool>(this, v => shown = v));
        });

        cut.FindAll("button").First(b => b.TextContent.Contains("Apply Filters")).Click();

        applied.Should().BeTrue();
        page.Should().Be(1);
        shown.Should().BeFalse();
        cut.Instance.CurrentPage.Should().Be(1);
        cut.FindAll(".modal-overlay").Should().BeEmpty();
    }

    [Fact]
    public void ResetClearsSearchAndResetsPage()
    {
        string? cleared = null;
        int? page = null;
        var cut = RenderModal(p =>
        {
            p.Add(x => x.CurrentPage, 2);
            p.Add(x => x.SearchText, "abc");
            p.Add(x => x.SearchTextChanged, EventCallback.Factory.Create<string>(this, v => cleared = v));
            p.Add(x => x.CurrentPageChanged, EventCallback.Factory.Create<int>(this, v => page = v));
        });

        cut.FindAll("button").First(b => b.TextContent.Contains("Reset")).Click();

        cleared.Should().Be("");
        page.Should().Be(1);
        cut.Instance.SearchText.Should().Be("");
    }

    [Fact]
    public void CloseButtonHidesModal()
    {
        bool? shown = null;
        var cut = RenderModal(p => p
            .Add(x => x.ShowFilterModalChanged, EventCallback.Factory.Create<bool>(this, v => shown = v)));

        cut.FindAll(".modal-header-dg button")[0].Click();

        shown.Should().BeFalse();
        cut.FindAll(".modal-overlay").Should().BeEmpty();
    }
}
