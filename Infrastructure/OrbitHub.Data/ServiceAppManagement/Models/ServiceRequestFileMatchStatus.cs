namespace OrbitHub.Data.ServiceAppManagement.Models;

/// <summary>
/// Represents the match status when searching for a service request file.
/// </summary>
public enum ServiceRequestFileMatchStatus : byte
{
    /// <summary>
    /// No matching file was found.
    /// </summary>
    NotFound = 0,

    /// <summary>
    /// Matched by file name only.
    /// </summary>
    MatchedByName = 1,

    /// <summary>
    /// Matched by compressed data only.
    /// </summary>
    MatchedByCompressedData = 2,

    /// <summary>
    /// Matched by both file name and compressed data.
    /// </summary>
    MatchedByBoth = 3
}