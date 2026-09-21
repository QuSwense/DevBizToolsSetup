namespace OrbitHub.Data.ServiceAppManagement.Models;

/// <summary>
/// Represents an item in the [dbo].[ServiceRequestFileEmbeddingLinkInput] table-valued parameter.
/// </summary>
public class SaveServiceRequestFileEmbeddingLinkInput
{
    public string ElementName { get; set; } = null!;

    public string XmlPath { get; set; } = null!;

    public int BinaryEmbeddingsStoreId { get; set; }

    public string Name { get; set; } = null!;

    public string? AdditionalDetails { get; set; }
}

