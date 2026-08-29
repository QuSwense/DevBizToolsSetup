using System.Text.RegularExpressions;

namespace OrbitHub.Common;

public static partial class NamingConventionValidator
{
    private static readonly Regex AppNameRegex = new(@"^[A-Za-z0-9äöüßÄÖÜ ]+$", RegexOptions.Compiled);
    private static readonly Regex WsdlPathRegex = new(@"^[A-Za-z0-9/?.&=_\-]+$", RegexOptions.Compiled);
    private static readonly Regex CSharpIdentifierRegex = new(@"^[A-Za-z_][A-Za-z0-9_]*$", RegexOptions.Compiled);

    private static readonly HashSet<string> CSharpKeywords = new(StringComparer.Ordinal)
    {
        "abstract","as","base","bool","break","byte","case","catch","char","checked","class",
        "const","continue","decimal","default","delegate","do","double","else","enum","event",
        "explicit","extern","false","finally","fixed","float","for","foreach","goto","if",
        "implicit","in","int","interface","internal","is","lock","long","namespace","new",
        "null","object","operator","out","override","params","private","protected","public",
        "readonly","ref","return","sbyte","sealed","short","sizeof","stackalloc","static",
        "string","struct","switch","this","throw","true","try","typeof","uint","ulong",
        "unchecked","unsafe","ushort","using","virtual","void","volatile","while"
    };

    public static bool IsValidAppName(string? value)
        => !string.IsNullOrWhiteSpace(value) && AppNameRegex.IsMatch(value.Trim());

    public static bool IsValidWsdlPath(string? value)
        => !string.IsNullOrWhiteSpace(value) && WsdlPathRegex.IsMatch(value.Trim());

    public static bool IsValidCSharpIdentifier(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return false;
        }

        var trimmed = value.Trim();
        return CSharpIdentifierRegex.IsMatch(trimmed) && !CSharpKeywords.Contains(trimmed);
    }
}
