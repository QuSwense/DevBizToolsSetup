using Microsoft.CodeAnalysis;
using Microsoft.CodeAnalysis.CSharp;

/// <summary>
/// Minifies C# source code by removing comments and extra whitespace,
/// leaving only single spaces between tokens.
/// </summary>
public class CodeMinifier : CSharpSyntaxRewriter
{
    public string Minify(string sourceCode)
    {
        SyntaxTree syntaxTree = CSharpSyntaxTree.ParseText(sourceCode);
        SyntaxNode root = syntaxTree.GetRoot();
        SyntaxNode minifiedRoot = Visit(root);
        return minifiedRoot.ToFullString();
    }

    public override SyntaxTrivia VisitTrivia(SyntaxTrivia trivia)
    {
        if (trivia.IsKind(SyntaxKind.WhitespaceTrivia))
        {
            return SyntaxFactory.Space; // keep a single space
        }
        // Remove everything else (comments, newlines, etc.)
        return default;
    }
}