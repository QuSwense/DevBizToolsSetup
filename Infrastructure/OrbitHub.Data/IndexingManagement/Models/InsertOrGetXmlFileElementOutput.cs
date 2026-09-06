namespace OrbitHub.Data.Repositories.IndexingManagement.Models;

public class InsertOrGetXmlFileElementOutput
{
    public long Id { get; set; }
    public string ElementName { get; set; } = string.Empty;
    public string XmlPath { get; set; } = string.Empty;
    public string ValueType { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public bool IsNew { get; set; }
}