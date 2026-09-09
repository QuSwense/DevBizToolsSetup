namespace OrbitHub.GenericModels.Models;

/// <summary>
/// Represents the result of a record version calculation.
/// Format: YY.QQ.NN (Year.Quarter.Revision).
/// </summary>
public sealed record RecordVersionModel
{
    /// <summary>Two-digit year (e.g., "26" for 2026).</summary>
    public required string Year { get; init; }

    /// <summary>Two-digit quarter (e.g., "03" for Q3).</summary>
    public required string Quarter { get; init; }

    /// <summary>Two-digit revision number.</summary>
    public required string Revision { get; init; }

    /// <summary>Returns the version string in YY.QQ.NN format.</summary>
    public override string ToString() => $"{Year}.{Quarter}.{Revision}";

    /// <summary>Parses a version string in YY.QQ.NN format.</summary>
    public static RecordVersionModel Parse(string version)
    {
        var parts = version.Split('.');
        if (parts.Length != 3)
            throw new FormatException($"Invalid record version format: '{version}'. Expected YY.QQ.NN.");

        return new RecordVersionModel
        {
            Year = parts[0],
            Quarter = parts[1],
            Revision = parts[2]
        };
    }
}
