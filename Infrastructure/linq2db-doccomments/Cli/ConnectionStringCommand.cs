using System.Text.Json;

namespace DocIntercept.Cli;

/// <summary>
/// <c>DocIntercept connection-string &lt;appsettings.json&gt;</c> - prints the
/// <c>ConnectionStrings:DefaultConnection</c> value. Replaces the inline
/// python3 JSON parsing that the scaffold shell scripts used to read the
/// connection string from appsettings.Development.json.
/// </summary>
internal static class ConnectionStringCommand
{
    public static int Run(string[] args)
    {
        if (args.Length == 0)
        {
            Console.Error.WriteLine("usage: DocIntercept connection-string <appsettings.json>");
            return 2;
        }

        if (args[0] is "--help" or "-h")
        {
            Console.WriteLine("usage: DocIntercept connection-string <appsettings.json>");
            return 0;
        }

        var path = args[0];
        if (!File.Exists(path))
        {
            Console.Error.WriteLine($"File not found: {path}");
            return 1;
        }

        using var document = JsonDocument.Parse(
            File.ReadAllText(path),
            new JsonDocumentOptions
            {
                CommentHandling = JsonCommentHandling.Skip,
                AllowTrailingCommas = true,
            });

        if (document.RootElement.TryGetProperty("ConnectionStrings", out var connectionStrings)
            && connectionStrings.TryGetProperty("DefaultConnection", out var value)
            && value.ValueKind == JsonValueKind.String)
        {
            Console.WriteLine(value.GetString());
            return 0;
        }

        Console.Error.WriteLine($"'ConnectionStrings:DefaultConnection' not found in {path}");
        return 1;
    }
}
