namespace ServiceHub.SoapEngine.Core.Services;

using System.Text.RegularExpressions;

/// <summary>
/// Generates and increments version identifiers in the format YY.QQ.NN
/// (Year, Quarter starting in January, Auto-increment number).
/// </summary>
public partial class SoapVersionGeneratorService
{
    [GeneratedRegex(@"^(\d{2})\.(10|20|30|40)\.(\d+)$")]
    private static partial Regex VersionRegex();

    /// <summary>
    /// Generates the next version string (YY.QQ.NN) based on current UTC time and previous version strings.
    /// </summary>
    /// <param name="latestVersionString">The latest existing version string from the database (e.g. "26.03.04").</param>
    public string GenerateNextVersion(string? latestVersionString = null)
    {
        var now = DateTime.UtcNow;
        string yy = now.ToString("yy");

        int quarterNumber = ((now.Month - 1) / 3) + 1;
        // Convert 1‑4 to 10,20,30,40
        string qq = (quarterNumber * 10).ToString("D2");
        string currentPrefix = $"{yy}.{qq}";

        if (string.IsNullOrWhiteSpace(latestVersionString))
            return $"{currentPrefix}.01";

        var match = VersionRegex().Match(latestVersionString);
        if (!match.Success)
            return $"{currentPrefix}.01";

        string previousPrefix = $"{match.Groups[1].Value}.{match.Groups[2].Value}";
        int previousSequence = int.Parse(match.Groups[3].Value);

        if (previousPrefix == currentPrefix)
        {
            int nextSequence = previousSequence + 1;
            return $"{currentPrefix}.{nextSequence:D2}";
        }

        return $"{currentPrefix}.01";
    }
}