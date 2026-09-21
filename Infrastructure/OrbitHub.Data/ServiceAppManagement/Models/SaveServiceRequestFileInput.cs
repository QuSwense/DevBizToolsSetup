namespace OrbitHub.Data.ServiceAppManagement.Models;

/// <summary>
/// Input model for stored procedure [dbo].[usp_SaveServiceRequestFile].
/// </summary>
public class SaveServiceRequestFileInput
{
    public int ServiceOperationId { get; set; }

    public string? FileFormat { get; set; }

    public string Name { get; set; } = null!;

    public byte[] CompressedData { get; set; } = [];

    public long? UncompressedSizeBytes { get; set; }

    public string? CompressionAlgorithmType { get; set; }

    public bool IsActive { get; set; } = true;

    public List<SaveServiceRequestFileEmbeddingLinkInput> EmbeddingLinks { get; set; } = [];

    public string? UserId { get; set; }
}

