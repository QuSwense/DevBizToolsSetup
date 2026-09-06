namespace OrbitHub.Data.Repositories.IndexingManagement.Models;

public class InsertOrGetXmlFileElementSearchOutput
{
    public long Id { get; set; }
    public long IndexingXmlFileElementId { get; set; }
    public string ElementValue { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public bool IsNew { get; set; }
}