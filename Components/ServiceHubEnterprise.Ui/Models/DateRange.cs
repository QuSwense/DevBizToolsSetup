namespace ServiceHubEnterprise.Ui.Models;

/// <summary>
/// Represents an inclusive date range used to filter dashboard sections.
/// </summary>
public sealed record DateRange(DateTime? Start, DateTime? End)
{
    /// <summary>
    /// Creates a range covering the last <paramref name="days"/> days (inclusive of today).
    /// </summary>
    public static DateRange LastDays(int days) => new(DateTime.Today.AddDays(-(days - 1)), DateTime.Today);

    /// <summary>
    /// Represents "all time" (no filtering).
    /// </summary>
    public static DateRange All => new(null, null);

    /// <summary>
    /// Gets whether this range applies no date filtering.
    /// </summary>
    public bool IsAll => Start is null && End is null;

    /// <summary>
    /// Gets a short human-readable label for the range.
    /// </summary>
    public string Label => IsAll
        ? "All time"
        : Start is null
            ? $"Until {End:MMM dd, yyyy}"
            : End is null
                ? $"From {Start:MMM dd, yyyy}"
                : $"{Start:MMM dd} – {End:MMM dd, yyyy}";

    /// <summary>
    /// Gets whether the given value falls within this range (inclusive, date granularity).
    /// </summary>
    public bool Includes(DateTime value)
    {
        var day = value.Date;
        if (Start.HasValue && day < Start.Value.Date)
        {
            return false;
        }

        if (End.HasValue && day > End.Value.Date)
        {
            return false;
        }

        return true;
    }
}
