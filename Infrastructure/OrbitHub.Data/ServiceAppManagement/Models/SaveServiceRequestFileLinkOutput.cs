namespace OrbitHub.Data.ServiceAppManagement.Models;

/// <summary>
/// Output model representing a link record (Result Set 2) from stored procedure [dbo].[usp_SaveServiceRequestFile].
/// </summary>
public class SaveServiceRequestFileLinkOutput
{
    public int LinkId { get; set; }

    public Guid PublicId { get; set; }

    public int ServiceRequestFileId { get; set; }

    public string ElementName { get; set; } = null!;

    public string XmlPath { get; set; } = null!;

    public int BinaryEmbeddingsStoreId { get; set; }

    public string Name { get; set; } = null!;

    public string? AdditionalDetails { get; set; }

    public DateTime CreatedAt { get; set; }

    public string CreatedBy { get; set; } = null!;
}

