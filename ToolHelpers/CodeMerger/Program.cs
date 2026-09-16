namespace CodeMerger;

/// <summary>
/// Command‑line entry point.
/// </summary>
public class Program
{
    public static async Task Main(string[] args)
    {
        if (args.Length == 0)
        {
            PrintUsage();
            return;
        }

        try
        {
            // Mode can be "cs", "sql" (minify each file) or "sqlmerge"
            // (minify and merge all files into one). Backwards compatible: when
            // the first argument is a plain folder path, C# mode is assumed.
            string firstArg = args[0].ToLowerInvariant();
            bool modeProvided = firstArg is "cs" or "csharp" or "sql" or "sqlmerge";
            string mode = modeProvided ? firstArg : "cs";
            int offset = modeProvided && mode == "cs" ? 1 : 0;

            if (mode is "sql")
            {
                if (args.Length < 2)
                {
                    Console.WriteLine($"Error: '{mode}' mode requires the path to a folder containing .sql scripts.");
                    PrintUsage();
                    return;
                }

                string sqlFolder = args[1];
                var sqlMinifier = new SqlMinifier();

                // Merge all scripts into one single output file.
                string mergedOutputFile = args.Length > 2
                    ? args[2]
                    : Path.Combine(Directory.GetCurrentDirectory(), "MergedOutput.sql");

                Console.WriteLine($"Minifying and merging SQL scripts in: {sqlFolder}");
                await sqlMinifier.MinifyFolderAsync(sqlFolder, mergedOutputFile);
                Console.WriteLine($"Merged SQL saved to: {Path.GetFullPath(mergedOutputFile)}");
            }
            else
            {
                if (args.Length <= offset)
                {
                    Console.WriteLine("Error: C# mode requires the path to a folder containing a .csproj.");
                    PrintUsage();
                    return;
                }

                string targetFolder = args[offset];
                string outputFile = 
                    args.Length > offset + 1
                    ? args[offset + 1]
                    : Path.Combine(Directory.GetCurrentDirectory(), "MergedOutput.cs");

                Console.WriteLine($"Processing directory: {targetFolder}");
                var processor = new CodeProcessor();
                await processor.MergeAndMinifyAsync(targetFolder, outputFile);
                Console.WriteLine($"Successfully saved minified merged source to: {Path.GetFullPath(outputFile)}");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error processing code: {ex.Message}");
            Console.WriteLine($"Error processing code: {ex.StackTrace}");
        }
    }

    private static void PrintUsage()
    {
        Console.WriteLine("Usage:");
        Console.WriteLine("  dotnet run -- cs       <path-to-folder-containing-csproj>      [optional-output-file]");
        Console.WriteLine("  dotnet run -- sql      <path-to-folder-containing-sql-scripts> [optional-output-folder]");
        Console.WriteLine("  dotnet run -- sqlmerge <path-to-folder-containing-sql-scripts> [optional-output-file]");
        Console.WriteLine();
        Console.WriteLine("  'sql'      minifies each .sql file into a mirrored output folder.");
        Console.WriteLine("  'sqlmerge' minifies all .sql files and merges them into one single file.");
        Console.WriteLine();
        Console.WriteLine("Backwards compatible: dotnet run -- <folder> [output] still runs C# mode.");
    }
}