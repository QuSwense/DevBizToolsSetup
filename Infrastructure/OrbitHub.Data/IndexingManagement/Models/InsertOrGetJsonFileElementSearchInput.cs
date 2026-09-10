namespace OrbitHub.Data.IndexingManagement.Models;

public class InsertOrGetJsonFileElementSearchInput
{
    public long IndexingJsonFileElementId { get; set; }
    public string ElementValue { get; set; } = default!;
    public string? UserId { get; set; }
}