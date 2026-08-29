using System.Text.RegularExpressions;

namespace DocIntercept.Formatting.Transformations;

/// <summary>
/// Inserts an empty line between consecutive class members so each property
/// (its doc comment, attributes and declaration) reads as its own block.
///
/// A member block starts at a <c>///</c> doc comment, a single-line attribute,
/// or an accessibility-qualified declaration (<c>public</c>/<c>internal</c>/
/// <c>protected</c>/<c>private</c>). Type declarations (class/interface/enum/
/// struct/record) are treated as their own grouping and do not trigger spacing.
///
/// A blank line is added before a new member block when the previously emitted
/// line is not already blank, is not <c>{</c>, and is not part of the same block
/// (i.e. a doc comment or attribute belonging to the same member).
/// </summary>
public sealed partial class MemberSpacingFormatter : ITextTransformation
{
    public string Apply(string content)
    {
        var lines = content.Split('\n');
        var result = new List<string>(lines.Length + 8);
        var atMemberBoundary = false;

        foreach (var line in lines)
        {
            if (IsDocComment(line) || IsAttribute(line))
            {
                if (atMemberBoundary && NeedsBlank(result))
                    result.Add(string.Empty);
                result.Add(line);
                atMemberBoundary = false;
            }
            else if (IsMemberDeclaration(line))
            {
                if (atMemberBoundary && NeedsBlank(result))
                    result.Add(string.Empty);
                result.Add(line);
                atMemberBoundary = true;
            }
            else
            {
                result.Add(line);
                atMemberBoundary = false;
            }
        }

        return string.Join('\n', result);
    }

    private static bool NeedsBlank(List<string> result) =>
        result.Count > 0 && result[^1].Length > 0;

    private static bool IsDocComment(string line) =>
        line.TrimStart().StartsWith("///", StringComparison.Ordinal);

    private static bool IsAttribute(string line)
    {
        var trimmed = line.Trim();
        return trimmed.StartsWith("[", StringComparison.Ordinal)
            && trimmed.EndsWith("]", StringComparison.Ordinal);
    }

    private static bool IsMemberDeclaration(string line)
    {
        var trimmed = line.TrimStart();
        return IsAccessibleDeclaration(trimmed) && !TypeKeywordRegex().IsMatch(trimmed);
    }

    private static bool IsAccessibleDeclaration(string trimmed) =>
        trimmed.StartsWith("public ", StringComparison.Ordinal)
        || trimmed.StartsWith("internal ", StringComparison.Ordinal)
        || trimmed.StartsWith("protected ", StringComparison.Ordinal)
        || trimmed.StartsWith("private ", StringComparison.Ordinal);

    [GeneratedRegex(@"\b(?:class|interface|enum|struct|record)\b")]
    private static partial Regex TypeKeywordRegex();
}
