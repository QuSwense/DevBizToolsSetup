namespace OrbitHub.Data.Repositories.IndexingManagement.Models;

public class InsertPdfFileElementMappingOutput
{
    public long Id { get; set; }
    public int? BinaryEmbeddingsStoreId { get; set; }
    public long IndexingPdfFileElementSearchId { get; set; }
    public bool IsNew { get; set; }
}