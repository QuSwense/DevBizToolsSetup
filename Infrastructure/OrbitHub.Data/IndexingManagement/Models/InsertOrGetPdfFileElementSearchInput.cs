namespace OrbitHub.Data.IndexingManagement.Models;

public class InsertOrGetPdfFileElementSearchInput
{
    public long IndexingPdfFileElementId { get; set; }
    public string ElementValue { get; set; } = default!;
    public string? UserId { get; set; }
}