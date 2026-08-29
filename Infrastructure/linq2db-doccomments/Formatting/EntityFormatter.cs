using System.Text;
using DocIntercept.Formatting.Transformations;
using DocIntercept.Settings;

namespace DocIntercept.Formatting;

/// <summary>
/// Orchestrates the post-scaffold formatting pipeline. Wraps the individual
/// <see cref="ITextTransformation"/> rules, normalizes line endings/trailing
/// newlines around them, and applies the result to a directory of generated
/// files - the same job format-entities.py used to perform.
/// </summary>
public sealed class EntityFormatter(ScaffoldFormatOptions options)
{
    private readonly ScaffoldFormatOptions _options = options;

    /// <summary>Formats a single source string (line-ending and BOM neutral).</summary>
    public string Format(string content)
    {
        var crlf = content.Contains("\r\n", StringComparison.Ordinal);
        var normalized = content.Replace("\r\n", "\n");

        foreach (var transformation in BuildTransformations())
            normalized = transformation.Apply(normalized);

        // Match format-entities.py: always end with exactly one trailing newline.
        normalized = normalized.TrimEnd('\n') + "\n";

        return crlf ? normalized.Replace("\n", "\r\n") : normalized;
    }

    /// <summary>
    /// Formats every matching file under <paramref name="directory"/> in place.
    /// Returns the number of files that changed. With <paramref name="dryRun"/>
    /// nothing is written and <c>formatted:</c> lines are still printed.
    /// </summary>
    public int FormatDirectory(string directory, bool dryRun = false, bool verbose = false)
    {
        if (!Directory.Exists(directory))
            throw new DirectoryNotFoundException($"Directory not found: {directory}");

        var searchOption = _options.RecurseSubdirectories
            ? SearchOption.AllDirectories
            : SearchOption.TopDirectoryOnly;

        var changed = 0;
        foreach (var file in Directory.EnumerateFiles(directory, _options.SearchPattern, searchOption))
        {
            var bytes = File.ReadAllBytes(file);
            var hasBom = bytes.Length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF;
            var original = hasBom
                ? Encoding.UTF8.GetString(bytes, 3, bytes.Length - 3)
                : Encoding.UTF8.GetString(bytes);

            var updated = Format(original);
            if (updated == original)
            {
                if (verbose)
                    Console.WriteLine($"unchanged: {file}");
                continue;
            }

            Console.WriteLine($"formatted: {file}");
            if (!dryRun)
            {
                var preamble = hasBom ? Encoding.UTF8.GetPreamble() : Array.Empty<byte>();
                var body = Encoding.UTF8.GetBytes(updated);
                File.WriteAllBytes(file, [.. preamble, .. body]);
            }

            changed++;
        }

        return changed;
    }

    private List<ITextTransformation> BuildTransformations()
    {
        var list = new List<ITextTransformation>();
        if (_options.SplitColumnAttributes)
            list.Add(new ColumnAttributeSplitter(_options.SqueezeAlignmentPadding));
        if (_options.FileScopedNamespaces)
            list.Add(new FileScopedNamespaceConverter());
        if (_options.BlankLineBetweenMembers)
            list.Add(new MemberSpacingFormatter());
        return list;
    }
}
