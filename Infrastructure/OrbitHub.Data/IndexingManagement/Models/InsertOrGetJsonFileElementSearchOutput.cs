namespace OrbitHub.Data.IndexingManagement.Models;

public class InsertOrGetJsonFileElementSearchOutput
{
    public long Id { get; set; }
    public long IndexingJsonFileElementId { get; set; }
    public string ElementValue { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public bool IsNew { get; set; }
}