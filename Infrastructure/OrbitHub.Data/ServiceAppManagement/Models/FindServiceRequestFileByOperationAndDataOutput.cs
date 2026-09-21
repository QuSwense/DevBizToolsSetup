namespace OrbitHub.Data.ServiceAppManagement.Models;

/// <summary>
/// Output model representing the found file record from stored procedure [dbo].[usp_FindServiceRequestFileByOperationAndData].
/// </summary>
public class FindServiceRequestFileByOperationAndDataOutput
{
    public int? ServiceRequestFileId { get; set; }

    public Guid? PublicId { get; set; }

    public int ServiceOperationId { get; set; }

    public string? FileFormat { get; set; }

    public string? Name { get; set; }

    public byte[]? CompressedData { get; set; }

    public long? UncompressedSizeBytes { get; set; }

    public string? CompressionAlgorithmType { get; set; }

    public string? RecordVersion { get; set; }

    public bool? IsActive { get; set; }

    public DateTime? CreatedAt { get; set; }

    public string? CreatedBy { get; set; }

    public ServiceRequestFileMatchStatus MatchStatus { get; set; }
}