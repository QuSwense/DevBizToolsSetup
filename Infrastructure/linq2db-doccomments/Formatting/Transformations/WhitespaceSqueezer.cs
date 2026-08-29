using System.Text.RegularExpressions;

namespace DocIntercept.Formatting.Transformations;

/// <summary>
/// Replicates the <c>squeeze</c> helper from the old format-entities.py:
/// collapses runs of 2+ spaces/tabs to a single space, removes whitespace
/// before commas and inside parentheses, then trims the ends. Applied to the
/// attribute and declaration halves of a split member line, never to whole
/// files (so alignment elsewhere is left alone).
/// </summary>
public static partial class WhitespaceSqueezer
{
    /// <summary>Collapses alignment padding and stray whitespace in a fragment.</summary>
    public static string Squeeze(string text)
    {
        text = MultipleWhitespaceRegex().Replace(text, " ");
        text = SpaceBeforeCommaRegex().Replace(text, ",");
        text = SpaceAfterOpenParenRegex().Replace(text, "(");
        text = SpaceBeforeCloseParenRegex().Replace(text, ")");
        return text.Trim();
    }

    [GeneratedRegex(@"[ \t]{2,}")]
    private static partial Regex MultipleWhitespaceRegex();

    [GeneratedRegex(@"\s+,")]
    private static partial Regex SpaceBeforeCommaRegex();

    [GeneratedRegex(@"\(\s+")]
    private static partial Regex SpaceAfterOpenParenRegex();

    [GeneratedRegex(@"\s+\)")]
    private static partial Regex SpaceBeforeCloseParenRegex();
}
