using DocIntercept.Formatting;
using DocIntercept.Settings;

namespace DocIntercept.Cli;

/// <summary>
/// <c>DocIntercept format &lt;directory&gt; [options]</c> - post-processes
/// scaffold output, replacing the old format-entities.py call in the shell
/// scripts. Settings load from DocIntercept.settings.json (next to the DLL) and
/// can be overridden per invocation.
/// </summary>
internal static class FormatCommand
{
    public static int Run(string[] args)
    {
        string? directory = null;
        string? settingsPath = null;
        var overrides = new Dictionary<string, string>(StringComparer.Ordinal);
        var dryRun = false;
        var verbose = false;

        for (var i = 0; i < args.Length; i++)
        {
            var arg = args[i];
            switch (arg)
            {
                case "--help":
                case "-h":
                    PrintUsage();
                    return 0;
                case "--dry-run":
                    dryRun = true;
                    continue;
                case "--verbose":
                    verbose = true;
                    continue;
            }

            if (arg.StartsWith("--", StringComparison.Ordinal))
            {
                var name = arg[2..];
                var equals = name.IndexOf('=');
                if (equals > 0)
                {
                    name = name[..equals];
                    overrides[name] = arg[(2 + equals + 1)..];
                }
                else if (i + 1 < args.Length && !args[i + 1].StartsWith("--", StringComparison.Ordinal))
                {
                    overrides[name] = args[++i];
                }
                else
                {
                    Console.Error.WriteLine($"Option '--{name}' requires a value.");
                    return 2;
                }

                if (name == "settings")
                {
                    settingsPath = overrides["settings"];
                    overrides.Remove("settings");
                }

                continue;
            }

            if (directory is null)
            {
                directory = arg;
                continue;
            }

            Console.Error.WriteLine($"Unexpected argument '{arg}'.");
            PrintUsage();
            return 2;
        }

        if (directory is null)
        {
            Console.Error.WriteLine("Missing <directory> argument.");
            PrintUsage();
            return 2;
        }

        var options = DocInterceptSettings.Load(settingsPath ?? DocInterceptSettings.DefaultSettingsPath()).ScaffoldFormat;
        var applyResult = ApplyOverrides(options, overrides);
        if (applyResult != 0)
            return applyResult;

        if (verbose)
            Console.WriteLine($"formatting {directory} (settings: {settingsPath ?? DocInterceptSettings.DefaultSettingsPath()})");

        try
        {
            var changed = new EntityFormatter(options).FormatDirectory(directory, dryRun, verbose);
            Console.WriteLine($"{(dryRun ? "would format" : "formatted")} {changed} file(s).");
            return 0;
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"Error: {ex.Message}");
            return 1;
        }
    }

    private static int ApplyOverrides(ScaffoldFormatOptions options, IReadOnlyDictionary<string, string> overrides)
    {
        foreach (var (key, value) in overrides)
        {
            switch (key)
            {
                case "split-column-attributes":
                    options.SplitColumnAttributes = ParseBool(key, value);
                    break;
                case "file-scoped-namespaces":
                    options.FileScopedNamespaces = ParseBool(key, value);
                    break;
                case "squeeze-alignment-padding":
                    options.SqueezeAlignmentPadding = ParseBool(key, value);
                    break;
                case "blank-line-between-members":
                    options.BlankLineBetweenMembers = ParseBool(key, value);
                    break;
                case "search-pattern":
                    options.SearchPattern = value;
                    break;
                case "recurse":
                    options.RecurseSubdirectories = ParseBool(key, value);
                    break;
                default:
                    Console.Error.WriteLine($"Unknown option '--{key}'.");
                    return 2;
            }
        }

        return 0;
    }

    private static bool ParseBool(string key, string value) =>
        bool.TryParse(value, out var parsed)
            ? parsed
            : throw new ArgumentException($"Invalid boolean value '{value}' for '--{key}'.");

    private static void PrintUsage()
    {
        Console.WriteLine("usage: DocIntercept format <directory> [options]");
        Console.WriteLine();
        Console.WriteLine("Post-processes linq2db scaffold output: splits [Column(...)]");
        Console.WriteLine("one-liners, converts to file-scoped namespaces and adds blank");
        Console.WriteLine("lines between members. Settings default to the scaffoldFormat");
        Console.WriteLine("section of DocIntercept.settings.json next to the DLL.");
        Console.WriteLine();
        Console.WriteLine("options:");
        Console.WriteLine("  --settings=<path>                  settings file to use");
        Console.WriteLine("  --split-column-attributes=<bool>   split [Column] one-liners (default true)");
        Console.WriteLine("  --file-scoped-namespaces=<bool>    namespace X { } -> namespace X; (default true)");
        Console.WriteLine("  --squeeze-alignment-padding=<bool> collapse alignment padding (default true)");
        Console.WriteLine("  --blank-line-between-members=<bool> blank line between members (default true)");
        Console.WriteLine("  --search-pattern=<glob>            file glob (default *.cs)");
        Console.WriteLine("  --recurse=<bool>                   recurse subdirectories (default true)");
        Console.WriteLine("  --dry-run                          report changes without writing");
        Console.WriteLine("  --verbose                          log unchanged files too");
        Console.WriteLine("  -h, --help                         show this help");
    }
}
