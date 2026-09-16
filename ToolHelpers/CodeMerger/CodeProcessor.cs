using System.Text;
using Microsoft.CodeAnalysis;

namespace CodeMerger;

/// <summary>
/// Processes a folder, merges all .cs files, minifies the result, and writes it.
/// </summary>
public class CodeProcessor
{
    private readonly CodeMinifier _minifier = new();

    public async Task MergeAndMinifyAsync(string folderPath, string outputPath)
    {
        string fullFolderPath = Path.GetFullPath(folderPath);
        if (!Directory.Exists(fullFolderPath))
        {
            throw new DirectoryNotFoundException($"Directory '{fullFolderPath}' does not exist.");
        }

        string[] csprojFiles = Directory.GetFiles(fullFolderPath, "*.csproj", SearchOption.AllDirectories);
        if (csprojFiles.Length == 0)
        {
            throw new FileNotFoundException("No .csproj file was found in the specified directory or its subdirectories.");
        }

        string[] csFiles = [.. Directory.GetFiles(fullFolderPath, "*.cs", SearchOption.AllDirectories)
            .Where(f => !f.Contains($"{Path.DirectorySeparatorChar}obj{Path.DirectorySeparatorChar}") &&
                        !f.Contains($"{Path.DirectorySeparatorChar}bin{Path.DirectorySeparatorChar}"))];

        if (csFiles.Length == 0)
        {
            throw new InvalidOperationException("No .cs files found (excluding obj/bin).");
        }

        // Merge all files into a single compilable source
        string mergedCode = CodeMergeEngine.Merge(csFiles);

        // Minify the merged code
        string minifiedCode = _minifier.Minify(mergedCode);

        // Write the result
        string? destinationDirectory = Path.GetDirectoryName(Path.GetFullPath(outputPath));
        if (!string.IsNullOrEmpty(destinationDirectory) && !Directory.Exists(destinationDirectory))
        {
            Directory.CreateDirectory(destinationDirectory);
        }

        await File.WriteAllTextAsync(outputPath, minifiedCode);
    }
}