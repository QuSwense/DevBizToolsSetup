using FluentAssertions;
using Microsoft.AspNetCore.Components;
using ServiceHubEnterprise.Ui.Components;
using ServiceHubEnterprise.Ui.Models;
using Xunit;

namespace ServiceHubEnterprise.Tests.Ui;

public class DateRangeFilterTests : BunitTestBase
{
    [Fact]
    public void RendersAllPresets()
    {
        var cut = Render<DateRangeFilter>(p => p
            .Add(x => x.Value, DateRange.LastDays(7)));

        cut.FindAll(".seg-btn").Select(b => b.TextContent.Trim())
            .Should().BeEquivalentTo("7d", "14d", "30d", "90d", "All");
    }

    [Fact]
    public void MarksActivePreset()
    {
        var cut = Render<DateRangeFilter>(p => p
            .Add(x => x.Value, DateRange.LastDays(7)));

        var active = cut.FindAll(".seg-btn").Where(b => b.ClassList.Contains("active")).Select(b => b.TextContent.Trim());
        active.Should().ContainSingle().Which.Should().Be("7d");
    }

    [Fact]
    public void ApplyingPresetInvokesValueChanged()
    {
        DateRange? received = null;
        var cut = Render<DateRangeFilter>(p => p
            .Add(x => x.Value, DateRange.LastDays(7))
            .Add(x => x.ValueChanged, EventCallback.Factory.Create<DateRange?>(this, r => received = r)));

        cut.FindAll(".seg-btn").First(b => b.TextContent.Trim() == "30d").Click();

        received.Should().NotBeNull();
        received!.Start.Should().Be(DateRange.LastDays(30).Start);
        received!.End.Should().Be(DateRange.LastDays(30).End);
    }

    [Fact]
    public void ApplyingAllPresetInvokesAllTimeRange()
    {
        DateRange? received = null;
        var cut = Render<DateRangeFilter>(p => p
            .Add(x => x.Value, DateRange.LastDays(7))
            .Add(x => x.ValueChanged, EventCallback.Factory.Create<DateRange?>(this, r => received = r)));

        cut.FindAll(".seg-btn").First(b => b.TextContent.Trim() == "All").Click();

        received.Should().NotBeNull();
        received!.IsAll.Should().BeTrue();
    }

    [Fact]
    public void ApplyUsesEnteredDates()
    {
        DateRange? received = null;
        var cut = Render<DateRangeFilter>(p => p
            .Add(x => x.Value, DateRange.All)
            .Add(x => x.ValueChanged, EventCallback.Factory.Create<DateRange?>(this, r => received = r)));

        cut.FindAll(".datepicker-input")[0].Change("2024-01-01");
        cut.FindAll(".datepicker-input")[1].Change("2024-01-31");
        cut.Find(".btn-date-apply").Click();

        received.Should().NotBeNull();
        received!.Start.Should().Be(new DateTime(2024, 1, 1));
        received!.End.Should().Be(new DateTime(2024, 1, 31));
    }

    [Fact]
    public void ClearInvokesAllTimeRange()
    {
        DateRange? received = null;
        var cut = Render<DateRangeFilter>(p => p
            .Add(x => x.Value, DateRange.LastDays(7))
            .Add(x => x.ValueChanged, EventCallback.Factory.Create<DateRange?>(this, r => received = r)));

        cut.Find(".btn-date-clear").Click();

        received.Should().NotBeNull();
        received!.IsAll.Should().BeTrue();
    }

    [Fact]
    public void HydratesDateInputsFromValue()
    {
        var cut = Render<DateRangeFilter>(p => p
            .Add(x => x.Value, DateRange.LastDays(7)));

        cut.FindAll(".datepicker-input")[0].GetAttribute("value")
            .Should().Be(DateRange.LastDays(7).Start!.Value.ToString("yyyy-MM-dd"));
        cut.FindAll(".datepicker-input")[1].GetAttribute("value")
            .Should().Be(DateRange.LastDays(7).End!.Value.ToString("yyyy-MM-dd"));
    }
}
