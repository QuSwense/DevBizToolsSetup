namespace OrbitHub.GenericModels.Enums;

/// <summary>
/// Defines compression algorithms used for storing compressed binary content.
/// Maps to CK_*_CompressionAlgorithmType: 'Zstandard', 'Brotli', 'Gzip', 'none'.
/// </summary>
public enum CompressionAlgorithm
{
    /// <summary>Zstandard compression (high compression ratio with good speed).</summary>
    Zstandard = 0,

    /// <summary>Brotli compression (Google's compression algorithm).</summary>
    Brotli = 1,

    /// <summary>Gzip compression (widely supported, standard compression).</summary>
    Gzip = 2,

    /// <summary>No compression applied.</summary>
    None = 3
}
