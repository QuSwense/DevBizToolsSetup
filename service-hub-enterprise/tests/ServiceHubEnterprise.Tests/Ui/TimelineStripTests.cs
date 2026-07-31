using FluentAssertions;
using ServiceHubEnterprise.Ui.Components;
using Xunit;

namespace ServiceHubEnterprise.Tests.Ui;

public class TimelineStripTests : BunitTestBase
{
    [Fact]
    public void RendersOneSegmentPerEntry()
    {
        var cut = Render<TimelineStrip>(p => p.Add(x => x.Segments, new[]
        {
            new TimelineStrip.Segment(60, "var(--sh-success)"),
            new TimelineStrip.Segment(40, "var(--sh-danger)")
        }));

        cut.FindAll(".timeline-seg").Should().HaveCount(2);
    }

    [Fact]
    public void RendersWidthAndColorPerSegment()
    {
        var cut = Render<TimelineStrip>(p => p.Add(x => x.Segments, new[]
        {
            new TimelineStrip.Segment(25, "red", "snippet")
        }));

        var seg = cut.Find(".timeline-seg");
        seg.GetAttribute("style").Should().Be("flex-basis:25%;background:red");
        seg.GetAttribute("title").Should().Be("snippet");
    }

    [Fact]
    public void RendersEmptyWhenNoSegments()
    {
        var cut = Render<TimelineStrip>(p => p.Add(x => x.Segments, Array.Empty<TimelineStrip.Segment>()));

        cut.FindAll(".timeline-seg").Should().BeEmpty();
    }
}
