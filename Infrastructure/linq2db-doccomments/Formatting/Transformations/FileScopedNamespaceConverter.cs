using System.Text.RegularExpressions;

namespace DocIntercept.Formatting.Transformations;

/// <summary>
/// Converts the scaffolder's block-scoped <c>namespace X { ... }</c> into a
/// file-scoped <c>namespace X;</c>, dedenting the body by one level. Files that
/// are already file-scoped (or use an inline <c>namespace X {</c>) are left
/// untouched. Replicates <c>to_file_scoped_namespace</c> from the old
/// format-entities.py (the scaffolder emits <c>#pragma</c>/<c>#nullable</c>
/// outside the namespace block, so they stay before the namespace).
/// </summary>
public sealed partial class FileScopedNamespaceConverter : ITextTransformation
{
    public string Apply(string content)
    {
        var lines = content.Split('\n');

        var namespaceIndex = FindNamespaceLine(lines);
        if (namespaceIndex < 0)
            return content;

        var closingIndex = FindClosingBrace(lines, namespaceIndex);
        if (closingIndex < 0)
            return content;

        var name = NamespaceRegex().Match(lines[namespaceIndex]).Groups["name"].Value;
        var body = Dedent(lines[(namespaceIndex + 2)..closingIndex]);

        var result = new List<string>(lines.Length + 2);
        result.AddRange(lines[..namespaceIndex]);
        result.Add($"namespace {name};");
        result.Add(string.Empty);
        result.AddRange(body);
        result.AddRange(lines[(closingIndex + 1)..]);

        return string.Join('\n', result);
    }

    /// <summary>
    /// Finds a <c>namespace X</c> line (no trailing <c>{</c>) whose next line is
    /// the opening brace - the shape the scaffolder produces.
    /// </summary>
    private static int FindNamespaceLine(string[] lines)
    {
        for (var i = 0; i < lines.Length - 1; i++)
        {
            if (NamespaceRegex().IsMatch(lines[i]) && lines[i + 1].Trim() == "{")
                return i;
        }

        return -1;
    }

    /// <summary>Finds the namespace's closing brace: the last <c>}</c> in the file.</summary>
    private static int FindClosingBrace(string[] lines, int namespaceIndex)
    {
        for (var i = lines.Length - 1; i > namespaceIndex; i--)
        {
            if (lines[i].Trim() == "}")
                return i;
        }

        return -1;
    }

    private static IEnumerable<string> Dedent(IEnumerable<string> body)
    {
        foreach (var line in body)
            yield return line.Length > 0 && (line[0] == '\t' || line[0] == ' ')
                ? line[1..]
                : line;
    }

    [GeneratedRegex(@"^namespace\s+(?<name>[\w.]+)\s*$")]
    private static partial Regex NamespaceRegex();
}
