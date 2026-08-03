using FluentAssertions;
using ServiceHubEnterprise.Ui.Components;
using Xunit;

namespace ServiceHubEnterprise.Tests.Ui;

public class KpiTileTests : BunitTestBase
{
    [Fact]
    public void RendersLabelAndValue()
    {
        var cut = Render<KpiTile>(p => p
            .Add(x => x.Label, "Uptime")
            .Add(x => x.Value, "99.9%"));

        cut.Find(".kpi-title").TextContent.Should().Be("Uptime");
        cut.Find(".kpi-value").TextContent.Should().Be("99.9%");
    }

    [Fact]
    public void RendersIconAndSubWhenProvided()
    {
        var cut = Render<KpiTile>(p => p
            .Add(x => x.Label, "Apps")
            .Add(x => x.Value, "12")
            .Add(x => x.Icon, "🟢")
            .Add(x => x.Sub, "3 disabled"));

        cut.Find(".kpi-icon").TextContent.Should().Be("🟢");
        cut.Find(".kpi-sub").TextContent.Should().Be("3 disabled");
    }

    [Fact]
    public void OmitsIconWhenEmpty()
    {
        var cut = Render<KpiTile>(p => p
            .Add(x => x.Label, "Apps")
            .Add(x => x.Value, "12"));

        cut.FindAll(".kpi-icon").Should().BeEmpty();
    }

    [Fact]
    public void OmitsSubWhenEmpty()
    {
        var cut = Render<KpiTile>(p => p
            .Add(x => x.Label, "Apps")
            .Add(x => x.Value, "12"));

        cut.FindAll(".kpi-sub").Should().BeEmpty();
    }

    [Fact]
    public void AppliesColorStyleWhenProvided()
    {
        var cut = Render<KpiTile>(p => p
            .Add(x => x.Label, "Apps")
            .Add(x => x.Value, "12")
            .Add(x => x.Color, "var(--sh-danger)"));

        var value = cut.Find(".kpi-value");
        value.GetAttribute("style").Should().Be("color:var(--sh-danger)");
    }

    [Fact]
    public void OmitsInlineStyleWhenNoColor()
    {
        var cut = Render<KpiTile>(p => p
            .Add(x => x.Label, "Apps")
            .Add(x => x.Value, "12"));

        // Blazor renders style="" for an empty value, so accept null or empty.
        cut.Find(".kpi-value").GetAttribute("style").Should().BeNullOrEmpty();
    }
}
