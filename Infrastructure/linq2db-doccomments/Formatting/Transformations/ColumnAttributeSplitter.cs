using System.Text;
using System.Text.RegularExpressions;

namespace DocIntercept.Formatting.Transformations;

/// <summary>
/// Splits the scaffolder's single-line
/// <c>[Column(...)] public Prop { get; set; } [// comment]</c> members into a
/// separate attribute line followed by a property line, collapsing the
/// alignment padding the scaffolder inserts. Only <c>[Column(...)]</c>
/// attributes are affected - the scaffolder already emits <c>[Association]</c>
/// and <c>[Table]</c> attributes on their own lines. Replicates
/// <c>split_member_lines</c>/<c>squeeze</c> from the old format-entities.py.
/// </summary>
public sealed partial class ColumnAttributeSplitter(bool squeeze = true) : ITextTransformation
{
    private readonly bool _squeeze = squeeze;

    public string Apply(string content)
    {
        var lines = content.Split('\n');
        var sb = new StringBuilder(content.Length + 32);

        foreach (var line in lines)
        {
            var match = MemberRegex().Match(line);
            if (!match.Success)
            {
                sb.Append(line).Append('\n');
                continue;
            }

            var indent = match.Groups["indent"].Value;
            var attr = match.Groups["attr"].Value;
            var rest = match.Groups["rest"].Value;

            sb.Append(indent).Append('[')
              .Append(_squeeze ? WhitespaceSqueezer.Squeeze(attr) : attr)
              .Append(']').Append('\n');
            sb.Append(indent)
              .Append(_squeeze ? WhitespaceSqueezer.Squeeze(rest) : rest)
              .Append('\n');
        }

        return sb.ToString();
    }

    [GeneratedRegex(@"^(?<indent>[ \t]*)\[(?<attr>Column\(.*?\))\][ \t]+(?<rest>public .+)$")]
    private static partial Regex MemberRegex();
}
