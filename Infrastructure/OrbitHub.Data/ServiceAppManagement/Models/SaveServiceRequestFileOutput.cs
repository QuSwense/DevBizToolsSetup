namespace OrbitHub.Data.ServiceAppManagement.Models;

/// <summary>
/// Output model representing the created file record (Result Set 1) from stored procedure [dbo].[usp_SaveServiceRequestFile].
/// </summary>
public class SaveServiceRequestFileOutput
{
    public int ServiceRequestFileId { get; set; }

    public Guid PublicId { get; set; }

    public int ServiceOperationId { get; set; }

    public string? FileFormat { get; set; }

    public string Name { get; set; } = null!;

    public long? UncompressedSizeBytes { get; set; }

    public string? CompressionAlgorithmType { get; set; }

    public string RecordVersion { get; set; } = null!;

    public bool IsActive { get; set; }

    public DateTime CreatedAt { get; set; }

    public string CreatedBy { get; set; } = null!;

    public bool WasCreated { get; set; }

    public string SaveResult { get; set; } = null!;
}

