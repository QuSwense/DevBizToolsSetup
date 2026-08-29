using DocIntercept.Cli;

namespace DocIntercept;

/// <summary>
/// CLI entry point for the DocIntercept assembly.
///
/// The same assembly doubles as a <c>--customize</c> interceptor for
/// <c>dotnet linq2db scaffold</c> (see <see cref="DescriptionInterceptors"/>);
/// when loaded that way <c>Main</c> is never invoked.
///
/// Commands:
///   format             post-process scaffold output (replaces format-entities.py)
///   connection-string  read ConnectionStrings:DefaultConnection from appsettings
/// </summary>
internal static class Program
{
    public static int Main(string[] args)
    {
        try
        {
            if (args.Length == 0)
            {
                PrintHelp();
                return 2;
            }

            return args[0].ToLowerInvariant() switch
            {
                "format" => FormatCommand.Run(args[1..]),
                "connection-string" => ConnectionStringCommand.Run(args[1..]),
                "-h" or "--help" or "help" => Help(),
                var unknown => UnknownCommand(unknown),
            };
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"Error: {ex.Message}");
            return 1;
        }
    }

    private static int UnknownCommand(string command)
    {
        Console.Error.WriteLine($"Unknown command '{command}'.");
        PrintHelp();
        return 2;
    }

    private static int Help()
    {
        PrintHelp();
        return 0;
    }

    private static void PrintHelp()
    {
        Console.WriteLine("DocIntercept - linq2db.cli scaffold customizer + formatter.");
        Console.WriteLine();
        Console.WriteLine("usage: DocIntercept <command> [arguments]");
        Console.WriteLine();
        Console.WriteLine("commands:");
        Console.WriteLine("  format <directory> [options]   format scaffold output");
        Console.WriteLine("  connection-string <appsettings.json>");
        Console.WriteLine("                                  print ConnectionStrings:DefaultConnection");
        Console.WriteLine("  help                            show this help");
        Console.WriteLine();
        Console.WriteLine("run 'DocIntercept <command> --help' for command details");
    }
}
