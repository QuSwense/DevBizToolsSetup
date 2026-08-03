using Microsoft.AspNetCore.Components;
using ServiceHubEnterprise.Grid.Components;

namespace ServiceHubEnterprise.Tests.Grid;

public class GridColumnTests : BunitTestBase
{
    [Fact]
    public void FieldValuesRenderInCells()
    {
        var cut = Render<ServiceHubGrid<GridItem>>(p => p
            .Add(x => x.Items, GridTestData.Items)
            .Add(x => x.Columns, GridTestData.Columns()));

        var cells = cut.FindAll("tbody tr")[0].QuerySelectorAll("td");
        cells[0].TextContent.Trim().Should().Be("Alpha");
        cells[1].TextContent.Trim().Should().Be("30");
        cells[2].TextContent.Trim().Should().Be("Berlin");
    }

    [Fact]
    public void UnaryExpressionFieldReportsMemberNameForSort()
    {
        string? col = null;
        var cut = Render<ServiceHubGrid<GridItem>>(p => p
            .Add(x => x.Items, GridTestData.Items)
            .Add(x => x.Columns, GridTestData.Columns()) // Age uses (object) convert
            .Add(x => x.RowIdSelector, i => i.Id)
            .Add(x => x.SortColumnChanged, EventCallback.Factory.Create<string?>(this, v => col = v)));

        cut.FindAll("th.sortable")[1].Click(); // Age

        col.Should().Be("Age");
    }

    [Fact]
    public void NonMemberExpressionIsNotSortable()
    {
        string? col = null;
        var columns = new List<GridColumn<GridItem>>
        {
            new() { Title = "Computed", Field = i => i.Name + "!", Sortable = true }
        };
        var cut = Render<ServiceHubGrid<GridItem>>(p => p
            .Add(x => x.Items, GridTestData.Items)
            .Add(x => x.Columns, columns)
            .Add(x => x.RowIdSelector, i => i.Id)
            .Add(x => x.SortColumnChanged, EventCallback.Factory.Create<string?>(this, v => col = v)));

        cut.Find("th.sortable").Click();

        col.Should().BeNull();
    }

    [Fact]
    public void ColumnWithoutFieldRendersEmptyCell()
    {
        var columns = new List<GridColumn<GridItem>> { new() { Title = "Blank" } };
        var cut = Render<ServiceHubGrid<GridItem>>(p => p
            .Add(x => x.Items, GridTestData.Items)
            .Add(x => x.Columns, columns));

        cut.Find("tbody td").TextContent.Should().Be("");
    }

    [Fact]
    public void TemplateOverridesFieldValue()
    {
        var columns = new List<GridColumn<GridItem>>
        {
            new()
            {
                Title = "Name",
                Field = i => i.Name,
                Template = item => b => b.AddMarkupContent(0, $"<strong class=\"tmpl\">{item.Name.ToUpper()}</strong>")
            }
        };
        var cut = Render<ServiceHubGrid<GridItem>>(p => p
            .Add(x => x.Items, GridTestData.Items)
            .Add(x => x.Columns, columns));

        cut.Find("tbody .tmpl").TextContent.Should().Be("ALPHA");
    }

    [Fact]
    public void DefaultRowIdSelectorProducesNonEmptyId()
    {
        var cut = Render<ServiceHubGrid<GridItem>>(p => p
            .Add(x => x.Items, GridTestData.Items)
            .Add(x => x.Columns, GridTestData.Columns()));

        cut.Find("tbody tr").GetAttribute("data-row-id").Should().NotBeNullOrEmpty();
    }

    [Fact]
    public void CellCssClassIsApplied()
    {
        var columns = new List<GridColumn<GridItem>>
        {
            new() { Title = "Name", Field = i => i.Name, CssClass = "name-cell" }
        };
        var cut = Render<ServiceHubGrid<GridItem>>(p => p
            .Add(x => x.Items, GridTestData.Items)
            .Add(x => x.Columns, columns));

        cut.Find("tbody td").ClassList.Contains("name-cell").Should().BeTrue();
    }
}
