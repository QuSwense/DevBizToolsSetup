using FluentAssertions;
using ServiceHubEnterprise.Ui.Components;
using Xunit;

namespace ServiceHubEnterprise.Tests.Ui;

public class MiniDonutTests : BunitTestBase
{
    [Fact]
    public void RendersPercentageFromValueAndTotal()
    {
        var cut = Render<MiniDonut>(p => p
            .Add(x => x.Value, 30)
            .Add(x => x.Total, 100));

        cut.Find(".donut-value").TextContent.Should().Be("30%");
    }

    [Fact]
    public void RendersZeroWhenTotalIsZero()
    {
        var cut = Render<MiniDonut>(p => p
            .Add(x => x.Value, 50)
            .Add(x => x.Total, 0));

        cut.Find(".donut-value").TextContent.Should().Be("0%");
    }

    [Fact]
    public void ClampsToIntegerDivision()
    {
        var cut = Render<MiniDonut>(p => p
            .Add(x => x.Value, 1)
            .Add(x => x.Total, 3));

        cut.Find(".donut-value").TextContent.Should().Be("33%");
    }

    [Fact]
    public void RendersValueArcWhenPctGreaterThanZero()
    {
        var cut = Render<MiniDonut>(p => p
            .Add(x => x.Value, 40)
            .Add(x => x.Total, 100)
            .Add(x => x.ValueColor, "var(--sh-success)"));

        cut.FindAll("circle").Should().HaveCount(2);
        var arc = cut.FindAll("circle")[1];
        arc.GetAttribute("stroke").Should().Be("var(--sh-success)");
        arc.GetAttribute("stroke-dasharray").Should().Be("40 60");
    }

    [Fact]
    public void OmitsValueArcWhenPctIsZero()
    {
        var cut = Render<MiniDonut>(p => p
            .Add(x => x.Value, 0)
            .Add(x => x.Total, 100));

        cut.FindAll("circle").Should().HaveCount(1);
    }

    [Fact]
    public void RendersLabelAndSize()
    {
        var cut = Render<MiniDonut>(p => p
            .Add(x => x.Value, 10)
            .Add(x => x.Total, 100)
            .Add(x => x.Label, "passed")
            .Add(x => x.Size, 56));

        cut.Find(".donut-sub").TextContent.Should().Be("passed");
        cut.Find(".donut-chart-wrapper").GetAttribute("style").Should().Contain("width:56px");
        cut.Find("svg").GetAttribute("width").Should().Be("56");
    }
}
