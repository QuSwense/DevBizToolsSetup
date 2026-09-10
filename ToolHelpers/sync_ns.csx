#r "nuget: Microsoft.CodeAnalysis.CSharp, 4.12.0"

using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.CSharp.Syntax;

var rootDir = Environment.CurrentDirectory;

var projFiles = Directory.GetFiles(rootDir, "*.csproj", SearchOption.AllDirectories)
    .Where(p => !p.Contains($"{Path.DirectorySeparatorChar}bin{Path.DirectorySeparatorChar}") &&
                !p.Contains($"{Path.DirectorySeparatorChar}obj{Path.DirectorySeparatorChar}") &&
                !p.Contains($"{Path.DirectorySeparatorChar}ToolHelpers{Path.DirectorySeparatorChar}"))
    .ToList();

if (projFiles.Count == 0)
{
    Console.WriteLine($"[Error] No .csproj files found in: {rootDir}");
    return;
}

Console.WriteLine($"Found {projFiles.Count} project(s).");

// Map: OldNamespace -> NewNamespace
var namespaceRewrites = new Dictionary<string, string>();
var allSourceFiles = new List<string>();
int declarationUpdates = 0;

// ============================================================================
// PASS 1: Update Namespace Declarations & Record Renames
// ============================================================================
Console.WriteLine("\n--- Pass 1: Syncing Namespace Declarations ---");

foreach (var projPath in projFiles)
{
    var projDir = Path.GetDirectoryName(projPath)!;
    var defaultNs = Path.GetFileNameWithoutExtension(projPath);

    var projXml = File.ReadAllText(projPath);
    var match = Regex.Match(projXml, @"<RootNamespace>([^<]+)</RootNamespace>");
    if (match.Success)
    {
        defaultNs = match.Groups[1].Value.Trim();
    }

    var csFiles = Directory.GetFiles(projDir, "*.cs", SearchOption.AllDirectories)
        .Where(f => !f.Contains($"{Path.DirectorySeparatorChar}bin{Path.DirectorySeparatorChar}") &&
                    !f.Contains($"{Path.DirectorySeparatorChar}obj{Path.DirectorySeparatorChar}") &&
                    !f.EndsWith(".Designer.cs") &&
                    !f.EndsWith("AssemblyInfo.cs"))
        .ToList();

    allSourceFiles.AddRange(csFiles);

    foreach (var file in csFiles)
    {
        var relDir = Path.GetRelativePath(projDir, Path.GetDirectoryName(file)!);
        var expectedNs = (relDir == "." || string.IsNullOrWhiteSpace(relDir))
            ? defaultNs
            : $"{defaultNs}.{relDir.Replace(Path.DirectorySeparatorChar, '.')}";

        var code = File.ReadAllText(file);
        var tree = CSharpSyntaxTree.ParseText(code);
        var root = tree.GetRoot();

        // 1. Check FileScopedNamespace
        var fileScoped = root.DescendantNodes().OfType<FileScopedNamespaceDeclarationSyntax>().FirstOrDefault();
        if (fileScoped != null)
        {
            var currentNs = fileScoped.Name.ToString();
            if (currentNs != expectedNs)
            {
                var updated = root.ReplaceNode(fileScoped, fileScoped.WithName(SyntaxFactory.ParseName(expectedNs)));
                File.WriteAllText(file, updated.ToFullString());
                namespaceRewrites[currentNs] = expectedNs;
                Console.WriteLine($"[Namespace Updated] {Path.GetFileName(file)}: {currentNs} -> {expectedNs}");
                declarationUpdates++;
            }
            continue;
        }

        // 2. Check BlockScopedNamespace
        var blockScoped = root.DescendantNodes().OfType<NamespaceDeclarationSyntax>().FirstOrDefault();
        if (blockScoped != null)
        {
            var currentNs = blockScoped.Name.ToString();
            if (currentNs != expectedNs)
            {
                var updated = root.ReplaceNode(blockScoped, blockScoped.WithName(SyntaxFactory.ParseName(expectedNs)));
                File.WriteAllText(file, updated.ToFullString());
                namespaceRewrites[currentNs] = expectedNs;
                Console.WriteLine($"[Namespace Updated] {Path.GetFileName(file)}: {currentNs} -> {expectedNs}");
                declarationUpdates++;
            }
        }
    }
}

Console.WriteLine($"\nPass 1 complete. Updated {declarationUpdates} namespace declarations.");

// ============================================================================
// PASS 2: Update 'using' References Across Entire Workspace
// ============================================================================
Console.WriteLine($"\n--- Pass 2: Updating Using Directives Across {allSourceFiles.Count} Files ---");

if (namespaceRewrites.Count == 0)
{
    Console.WriteLine("No namespace changes detected. Done.");
    return;
}

int filesWithUpdatedUsings = 0;

foreach (var file in allSourceFiles)
{
    var code = File.ReadAllText(file);
    var tree = CSharpSyntaxTree.ParseText(code);
    var root = tree.GetRoot();

    var usings = root.DescendantNodes().OfType<UsingDirectiveSyntax>().ToList();
    var replacements = new Dictionary<UsingDirectiveSyntax, UsingDirectiveSyntax>();

    foreach (var usingDirective in usings)
    {
        if (usingDirective.Name == null) continue;
        var importedNs = usingDirective.Name.ToString();

        if (namespaceRewrites.TryGetValue(importedNs, out var targetNs))
        {
            var newName = SyntaxFactory.ParseName(targetNs)
                .WithTriviaFrom(usingDirective.Name);

            var newUsing = usingDirective.WithName(newName);
            replacements[usingDirective] = newUsing;
        }
    }

    if (replacements.Count > 0)
    {
        var updatedRoot = root.ReplaceNodes(
            replacements.Keys,
            (original, _) => replacements[original]
        );

        File.WriteAllText(file, updatedRoot.ToFullString());
        Console.WriteLine($"[Usings Updated] {Path.GetFileName(file)} ({replacements.Count} import(s) updated)");
        filesWithUpdatedUsings++;
    }
}

Console.WriteLine($"\nCompleted. Updated namespaces in {declarationUpdates} files and usings in {filesWithUpdatedUsings} files.");