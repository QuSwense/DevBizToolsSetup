using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.CSharp.Syntax;

/// <summary>
/// Merges multiple C# source files into a single compilable file.
/// All using directives are placed at the top, and namespace declarations are combined.
/// </summary>
public static class CodeMergeEngine
{
    /// <summary>
    /// Merges the given C# files into one compilable source string.
    /// </summary>
    public static string Merge(IEnumerable<string> filePaths)
    {
        var allUsings = new HashSet<UsingDirectiveSyntax>(UsingDirectiveComparer.Instance);
        var namespaceMembers = new Dictionary<string, List<MemberDeclarationSyntax>>();
        var globalMembers = new List<MemberDeclarationSyntax>();

        foreach (var filePath in filePaths)
        {
            string source = File.ReadAllText(filePath);
            var tree = CSharpSyntaxTree.ParseText(source);
            var root = tree.GetCompilationUnitRoot();

            // Collect all top-level using directives
            foreach (var usingDirective in root.Usings)
            {
                allUsings.Add(usingDirective);
            }

            // Process top-level members (namespace declarations, types, etc.)
            foreach (var member in root.Members)
            {
                ProcessMember(member, string.Empty, namespaceMembers, globalMembers);
            }
        }

        // Build the final compilation unit
        var usingsList = allUsings
            .OrderBy(u => u.Name.ToString())
            .ToList();

        var membersList = new List<MemberDeclarationSyntax>();

        // Add global (namespace‑less) members first
        membersList.AddRange(globalMembers);

        // Add combined namespace declarations
        foreach (var kvp in namespaceMembers.OrderBy(k => k.Key))
        {
            var nsDecl = CreateNamespaceDeclaration(kvp.Key, kvp.Value);
            membersList.Add(nsDecl);
        }

        var unit = SyntaxFactory.CompilationUnit()
            .WithUsings(SyntaxFactory.List(usingsList))
            .WithMembers(SyntaxFactory.List(membersList))
            .NormalizeWhitespace();

        return unit.ToFullString();
    }

    /// <summary>
    /// Recursively processes a member, collecting types into the appropriate namespace bucket.
    /// </summary>
    private static void ProcessMember(
        MemberDeclarationSyntax member,
        string currentNamespace,
        Dictionary<string, List<MemberDeclarationSyntax>> namespaceMembers,
        List<MemberDeclarationSyntax> globalMembers)
    {
        if (member is NamespaceDeclarationSyntax nsDecl)
        {
            string fullNs = GetFullNamespaceName(currentNamespace, nsDecl.Name);
            foreach (var child in nsDecl.Members)
            {
                ProcessMember(child, fullNs, namespaceMembers, globalMembers);
            }
        }
        else if (member is FileScopedNamespaceDeclarationSyntax fileScopedNs)
        {
            string fullNs = GetFullNamespaceName(currentNamespace, fileScopedNs.Name);
            foreach (var child in fileScopedNs.Members)
            {
                ProcessMember(child, fullNs, namespaceMembers, globalMembers);
            }
        }
        else
        {
            // It's a class, struct, enum, delegate, etc.
            if (string.IsNullOrEmpty(currentNamespace))
                globalMembers.Add(member);
            else
            {
                if (!namespaceMembers.TryGetValue(currentNamespace, out var list))
                {
                    list = new List<MemberDeclarationSyntax>();
                    namespaceMembers[currentNamespace] = list;
                }
                list.Add(member);
            }
        }
    }

    private static string GetFullNamespaceName(string parent, NameSyntax name)
        => string.IsNullOrEmpty(parent) ? name.ToString() : parent + "." + name.ToString();

    /// <summary>
    /// Creates a nested namespace declaration for a dotted namespace name.
    /// </summary>
    private static NamespaceDeclarationSyntax CreateNamespaceDeclaration(
        string fullName,
        List<MemberDeclarationSyntax> members)
    {
        var parts = fullName.Split('.');
        NamespaceDeclarationSyntax? current = null;

        for (int i = parts.Length - 1; i >= 0; i--)
        {
            var name = SyntaxFactory.IdentifierName(parts[i]);
            current = SyntaxFactory.NamespaceDeclaration(name)
                .WithMembers(current == null
                    ? SyntaxFactory.List(members)
                    : SyntaxFactory.SingletonList<MemberDeclarationSyntax>(current));
        }

        return current!;
    }

    /// <summary>
    /// Compares using directives by alias and name to eliminate duplicates.
    /// </summary>
    private class UsingDirectiveComparer : IEqualityComparer<UsingDirectiveSyntax>
    {
        public static readonly UsingDirectiveComparer Instance = new();

        public bool Equals(UsingDirectiveSyntax? x, UsingDirectiveSyntax? y)
        {
            if (ReferenceEquals(x, y)) return true;
            if (x is null || y is null) return false;

            string? xAlias = x.Alias?.Name.ToString();
            string? yAlias = y.Alias?.Name.ToString();
            if (xAlias != yAlias) return false;

            string xName = x.Name.ToString();
            string yName = y.Name.ToString();
            return xName == yName;
        }

        public int GetHashCode(UsingDirectiveSyntax obj)
        {
            string alias = obj.Alias?.Name.ToString() ?? "";
            string name = obj.Name.ToString();
            return (alias + "|" + name).GetHashCode();
        }
    }
}