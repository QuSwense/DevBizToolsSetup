namespace OrbitHub.GenericModels.Models;

/// <summary>
/// Represents compressed binary content with metadata about the compression algorithm and integrity hash.
/// Shared pattern across ServiceRequestFiles, ServiceResponseFiles, ServiceDefinitionSyncs,
/// ServiceOperationSchemas, SoapNamespaces, and RuleExecutionLogs.
/// </summary>
public sealed class CompressedContent
{
    /// <summary>The compressed binary data.</summary>
    public required byte[] CompressedData { get; init; }

    /// <summary>Size of the uncompressed data in bytes, or null if unknown.</summary>
    public int? UncompressedSizeBytes { get; init; }

    /// <summary>SHA-256 hex hash of the uncompressed content for integrity verification.</summary>
    public string? ContentHash { get; init; }
}
