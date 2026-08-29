using FluentAssertions;
using Microsoft.AspNetCore.Components;
using ServiceHubEnterprise.Ui.Components;
using ServiceHubEnterprise.Ui.Models;
using Xunit;

namespace ServiceHubEnterprise.Tests.Ui;

public class SectionCardTests : BunitTestBase
{
    private static RenderFragment Fragment(string markup) => b => b.AddMarkupContent(0, markup);

    [Fact]
    public void RendersTitleSubtitleAndIcon()
    {
        var cut = Render<SectionCard>(p => p
            .Add(x => x.Title, "SOAP Applications")
            .Add(x => x.Information, "6 configured")
            .Add(x => x.Icon, "📡"));

        cut.Find(".card-title").TextContent.Should().Be("SOAP Applications");
        cut.Find(".section-subtitle").TextContent.Should().Be("6 configured");
        cut.Find(".section-icon").TextContent.Should().Be("📡");
    }

    [Fact]
    public void RendersBodyAndFooter()
    {
        var cut = Render<SectionCard>(p => p
            .Add(x => x.Title, "SOAP")
            .Add(x => x.ChildContent, Fragment("<div class=\"body\">content</div>"))
            .Add(x => x.Footer, Fragment("<div class=\"foot\">footer</div>")));

        cut.Find(".section-body .body").TextContent.Should().Be("content");
        cut.Find(".section-footer .foot").TextContent.Should().Be("footer");
    }

    [Fact]
    public void RendersHeaderActions()
    {
        var cut = Render<SectionCard>(p => p
            .Add(x => x.Title, "SOAP")
            .Add(x => x.HeaderActions, Fragment("<button class=\"ha\">Go</button>")));

        cut.Find(".ha").TextContent.Should().Be("Go");
    }

    [Fact]
    public void FilterPillShowsAndTogglesDateRangeDialog()
    {
        var cut = Render<SectionCard>(p => p
            .Add(x => x.Title, "SOAP")
            .Add(x => x.Filter, DateRange.LastDays(7)));

        // Dialog hidden until the filter pill is clicked.
        cut.FindAll(".daterange-popup").Should().BeEmpty();
        cut.Find(".filter-pill").Click();

        cut.FindAll(".daterange-popup").Should().HaveCount(1);
    }

    [Fact]
    public void FilterChangeClosesDialogAndInvokesOnFilterChanged()
    {
        DateRange? received = null;
        var cut = Render<SectionCard>(p => p
            .Add(x => x.Title, "SOAP")
            .Add(x => x.Filter, DateRange.LastDays(7))
            .Add(x => x.OnFilterChanged, EventCallback.Factory.Create<DateRange?>(this, r => received = r)));

        cut.Find(".filter-pill").Click();
        cut.FindAll(".seg-btn").First(b => b.TextContent.Trim() == "30d").Click();

        received.Should().NotBeNull();
        received!.Start.Should().Be(DateRange.LastDays(30).Start);
        received!.End.Should().Be(DateRange.LastDays(30).End);
        // Dialog is closed after applying.
        cut.FindAll(".daterange-popup").Should().BeEmpty();
    }

    [Fact]
    public void CollapsedCollapsibleRendersSummaryInsteadOfBody()
    {
        var cut = Render<SectionCard>(p => p
            .Add(x => x.Title, "SOAP")
            .Add(x => x.Collapsible, true)
            .Add(x => x.Collapsed, true)
            .Add(x => x.Summary, Fragment("<div class=\"summary\">compact</div>"))
            .Add(x => x.ChildContent, Fragment("<div class=\"body\">full</div>")));

        cut.Find(".section-summary .summary").TextContent.Should().Be("compact");
        cut.FindAll(".section-body").Should().BeEmpty();
        cut.Find(".section-toggle").TextContent.Should().Contain("Show details");
    }

    [Fact]
    public void ExpandedCollapsibleRendersBodyAndHideToggle()
    {
        var cut = Render<SectionCard>(p => p
            .Add(x => x.Title, "SOAP")
            .Add(x => x.Collapsible, true)
            .Add(x => x.Collapsed, false)
            .Add(x => x.Summary, Fragment("<div class=\"summary\">compact</div>"))
            .Add(x => x.ChildContent, Fragment("<div class=\"body\">full</div>")));

        cut.Find(".section-body .body").TextContent.Should().Be("full");
        cut.FindAll(".section-summary").Should().BeEmpty();
        cut.Find(".section-toggle").TextContent.Should().Contain("Hide details");
    }

    [Fact]
    public void NonCollapsibleShowsNoToggle()
    {
        var cut = Render<SectionCard>(p => p
            .Add(x => x.Title, "SOAP")
            .Add(x => x.ChildContent, Fragment("<div class=\"body\">full</div>")));

        cut.FindAll(".section-toggle").Should().BeEmpty();
        cut.Find(".section-body .body").TextContent.Should().Be("full");
    }

    [Fact]
    public void ToggleInvokesOnToggleWithNextState()
    {
        bool? toggled = null;
        var cut = Render<SectionCard>(p => p
            .Add(x => x.Title, "SOAP")
            .Add(x => x.Collapsible, true)
            .Add(x => x.Collapsed, false)
            .Add(x => x.OnToggle, EventCallback.Factory.Create<bool>(this, v => toggled = v)));

        cut.Find(".section-toggle").Click();

        toggled.Should().BeTrue();
    }
}
