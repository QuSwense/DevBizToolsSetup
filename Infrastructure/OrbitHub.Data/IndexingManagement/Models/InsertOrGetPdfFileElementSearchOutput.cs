namespace OrbitHub.Data.Repositories.IndexingManagement.Models;

public class InsertOrGetPdfFileElementSearchOutput
{
    public long Id { get; set; }
    public long IndexingPdfFileElementId { get; set; }
    public string ElementValue { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public bool IsNew { get; set; }
}