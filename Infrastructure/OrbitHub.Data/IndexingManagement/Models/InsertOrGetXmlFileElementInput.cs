namespace OrbitHub.Data.Repositories.IndexingManagement.Models;

public class InsertOrGetXmlFileElementInput
{
    public string ElementName { get; set; } = default!;
    public string XmlPath { get; set; } = default!;
    public string? ValueType { get; set; }
    public string? UserId { get; set; }
}