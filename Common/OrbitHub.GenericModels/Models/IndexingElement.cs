namespace OrbitHub.GenericModels.Models;

/// <summary>
/// Represents an indexing element entry for XML, JSON, or PDF file element indexing (EAV pattern).
/// Shared structure across IndexingXmlFileElements, IndexingJsonFileElements, and IndexingPdfFileElements.
/// </summary>
public sealed record IndexingElement
{
    /// <summary>Name of the element (e.g., "customer", "orderId").</summary>
    public required string ElementName { get; init; }

    /// <summary>Path to the element within the document (e.g., "/root/customer/name").</summary>
    public required string ElementPath { get; init; }

    /// <summary>Hash of the element path for efficient lookups.</summary>
    public required string PathHash { get; init; }

    /// <summary>Frequency count of this element across indexed files.</summary>
    public int FrequencyCount { get; init; }
}
