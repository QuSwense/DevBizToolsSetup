using FluentAssertions;
using ServiceHubEnterprise.Ui.Models;
using Xunit;

namespace ServiceHubEnterprise.Tests.Ui;

public class DateRangeModelTests
{
    [Fact]
    public void LastDaysIncludesToday()
    {
        var range = DateRange.LastDays(7);

        range.Start.Should().Be(DateTime.Today.AddDays(-6));
        range.End.Should().Be(DateTime.Today);
        range.IsAll.Should().BeFalse();
    }

    [Fact]
    public void AllHasNoBounds()
    {
        var range = DateRange.All;

        range.Start.Should().BeNull();
        range.End.Should().BeNull();
        range.IsAll.Should().BeTrue();
    }

    [Fact]
    public void AllLabelIsAllTime()
    {
        DateRange.All.Label.Should().Be("All time");
    }

    [Fact]
    public void LabelFormatsStartAndEnd()
    {
        var range = new DateRange(new DateTime(2024, 1, 1), new DateTime(2024, 1, 31));
        range.Label.Should().Contain("Jan 01");
        range.Label.Should().Contain("Jan 31, 2024");
    }

    [Fact]
    public void IncludesReturnsTrueInsideRange()
    {
        var range = new DateRange(new DateTime(2024, 1, 1), new DateTime(2024, 1, 31));

        range.Includes(new DateTime(2024, 1, 15)).Should().BeTrue();
        range.Includes(new DateTime(2024, 1, 1)).Should().BeTrue(); // inclusive start
        range.Includes(new DateTime(2024, 1, 31)).Should().BeTrue(); // inclusive end
    }

    [Fact]
    public void IncludesReturnsFalseOutsideRange()
    {
        var range = new DateRange(new DateTime(2024, 1, 1), new DateTime(2024, 1, 31));

        range.Includes(new DateTime(2023, 12, 31)).Should().BeFalse();
        range.Includes(new DateTime(2024, 2, 1)).Should().BeFalse();
    }

    [Fact]
    public void IncludesHonorsOnlyStartBound()
    {
        var range = new DateRange(new DateTime(2024, 1, 1), null);

        range.Includes(new DateTime(2024, 6, 1)).Should().BeTrue();
        range.Includes(new DateTime(2023, 12, 31)).Should().BeFalse();
    }

    [Fact]
    public void IncludesHonorsOnlyEndBound()
    {
        var range = new DateRange(null, new DateTime(2024, 1, 31));

        range.Includes(new DateTime(2023, 6, 1)).Should().BeTrue();
        range.Includes(new DateTime(2024, 2, 1)).Should().BeFalse();
    }
}
