namespace OrbitHub.Data.Repositories.IndexingManagement.Models;

public class InsertPdfFileElementMappingInput
{
    public long IndexingPdfFileElementSearchId { get; set; }
    public int? BinaryEmbeddingsStoreId { get; set; }
    public string? UserId { get; set; }
}