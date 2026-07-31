using Microsoft.AspNetCore.Components;
using ServiceHubEnterprise.Grid.Components;

namespace ServiceHubEnterprise.Tests.Grid;

public class ServiceHubGridContextMenuTests : BunitTestBase
{
    private static Task<List<ContextMenuItem>> Provider(GridItem _)
        => Task.FromResult(new List<ContextMenuItem>
        {
            new() { Action = "edit", Label = "Edit", Icon = "bi-pencil" },
            new() { Action = "delete", Label = "Delete", Danger = true, Disabled = true },
            new() { Action = "sep", Label = "", Type = "divider" }
        });

    private IRenderedComponent<ServiceHubGrid<GridItem>> RenderGrid(
        Action<ComponentParameterCollectionBuilder<ServiceHubGrid<GridItem>>>? extra = null)
        => Render<ServiceHubGrid<GridItem>>((ComponentParameterCollectionBuilder<ServiceHubGrid<GridItem>> p) =>
        {
            p.Add(x => x.Items, GridTestData.Items);
            p.Add(x => x.Columns, GridTestData.Columns());
            p.Add(x => x.RowIdSelector, i => i.Id);
            p.Add(x => x.ContextMenuItemsProvider, Provider);
            extra?.Invoke(p);
        });

    [Fact]
    public async Task GetContextMenuItemsReturnsProviderItems()
    {
        var cut = RenderGrid();

        var menu = await cut.InvokeAsync(() => cut.Instance.GetContextMenuItems("r1"));

        menu.Should().HaveCount(3);
        menu[0].Action.Should().Be("edit");
        menu[0].Icon.Should().Be("bi-pencil");
        menu[1].Danger.Should().BeTrue();
        menu[1].Disabled.Should().BeTrue();
        menu[2].Type.Should().Be("divider");
    }

    [Fact]
    public async Task GetContextMenuItemsReturnsEmptyForUnknownRow()
    {
        var cut = RenderGrid();

        var menu = await cut.InvokeAsync(() => cut.Instance.GetContextMenuItems("nope"));

        menu.Should().BeEmpty();
    }

    [Fact]
    public async Task GetContextMenuItemsReturnsEmptyWithoutProvider()
    {
        var cut = Render<ServiceHubGrid<GridItem>>(p => p
            .Add(x => x.Items, GridTestData.Items)
            .Add(x => x.Columns, GridTestData.Columns())
            .Add(x => x.RowIdSelector, i => i.Id));

        var menu = await cut.InvokeAsync(() => cut.Instance.GetContextMenuItems("r1"));

        menu.Should().BeEmpty();
    }

    [Fact]
    public async Task HandleContextMenuActionForwardsToCallback()
    {
        (string action, GridItem item)? received = null;
        var cut = RenderGrid(p => p
            .Add(x => x.ContextMenuItemClicked, EventCallback.Factory.Create<(string, GridItem)>(this, v => received = v)));

        await cut.InvokeAsync(() => cut.Instance.HandleContextMenuAction("r1", "edit"));

        received.Should().NotBeNull();
        received!.Value.action.Should().Be("edit");
        received.Value.item.Id.Should().Be("r1");
    }

    [Fact]
    public async Task HandleContextMenuActionIgnoresUnknownRow()
    {
        (string action, GridItem item)? received = null;
        var cut = RenderGrid(p => p
            .Add(x => x.ContextMenuItemClicked, EventCallback.Factory.Create<(string, GridItem)>(this, v => received = v)));

        await cut.InvokeAsync(() => cut.Instance.HandleContextMenuAction("nope", "edit"));

        received.Should().BeNull();
    }

    [Fact]
    public async Task CloseBlazorActionRowForwardsRowId()
    {
        string? closed = null;
        var cut = RenderGrid(p => p
            .Add(x => x.ActionRowClosed, EventCallback.Factory.Create<string>(this, v => closed = v)));

        await cut.InvokeAsync(() => cut.Instance.CloseBlazorActionRow("r2"));

        closed.Should().Be("r2");
    }
}
