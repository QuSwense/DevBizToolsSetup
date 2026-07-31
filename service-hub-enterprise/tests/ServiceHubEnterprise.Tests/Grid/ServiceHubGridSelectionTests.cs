using Microsoft.AspNetCore.Components;
using ServiceHubEnterprise.Grid.Components;

namespace ServiceHubEnterprise.Tests.Grid;

public class ServiceHubGridSelectionTests : BunitTestBase
{
    private IRenderedComponent<ServiceHubGrid<GridItem>> RenderSelection(
        Action<ComponentParameterCollectionBuilder<ServiceHubGrid<GridItem>>>? extra = null)
        => Render<ServiceHubGrid<GridItem>>((ComponentParameterCollectionBuilder<ServiceHubGrid<GridItem>> p) =>
        {
            p.Add(x => x.Items, GridTestData.Items);
            p.Add(x => x.Columns, GridTestData.Columns());
            p.Add(x => x.RowIdSelector, i => i.Id);
            p.Add(x => x.EnableSelection, true);
            extra?.Invoke(p);
        });

    [Fact]
    public void RowCheckboxAddsToSelectedIds()
    {
        HashSet<string>? changed = null;
        var cut = RenderSelection(p => p
            .Add(x => x.SelectionChanged, EventCallback.Factory.Create<HashSet<string>>(this, v => changed = v)));

        cut.FindAll("input[aria-label='Select row']")[0].Click();

        cut.Instance.SelectedIds.Should().Contain("r1");
        changed.Should().Contain("r1");
        cut.FindAll(".meta-pill").Any(p => p.TextContent.Trim() == "1 selected").Should().BeTrue();
    }

    [Fact]
    public void RowCheckboxDeselectsWhenClickedTwice()
    {
        var cut = RenderSelection();

        cut.FindAll("input[aria-label='Select row']")[0].Click();
        cut.FindAll("input[aria-label='Select row']")[0].Click();

        cut.Instance.SelectedIds.Should().NotContain("r1");
    }

    [Fact]
    public void SelectAllSelectsAllVisibleRows()
    {
        var cut = RenderSelection();

        cut.Find("input[aria-label='Select all']").Click();

        cut.Instance.SelectedIds.Should().HaveCount(GridTestData.Items.Length);
        cut.Find("input[aria-label='Select all']").HasAttribute("checked").Should().BeTrue();
    }

    [Fact]
    public void SelectAllTogglesOffWhenAlreadyAllSelected()
    {
        var cut = RenderSelection();

        cut.Find("input[aria-label='Select all']").Click();
        cut.Find("input[aria-label='Select all']").Click();

        cut.Instance.SelectedIds.Should().BeEmpty();
    }

    [Fact]
    public void HeaderCheckboxReflectsPartialSelection()
    {
        var cut = RenderSelection();

        cut.FindAll("input[aria-label='Select row']")[0].Click();

        // Not all rows selected → select-all box is unchecked.
        cut.Find("input[aria-label='Select all']").HasAttribute("checked").Should().BeFalse();
    }

    [Fact]
    public void InvokesSelectedIdsChangedWithUpdatedSet()
    {
        HashSet<string>? ids = null;
        var cut = RenderSelection(p => p
            .Add(x => x.SelectedIdsChanged, EventCallback.Factory.Create<HashSet<string>>(this, v => ids = v)));

        cut.FindAll("input[aria-label='Select row']")[0].Click();

        ids.Should().Contain("r1");
    }
}
