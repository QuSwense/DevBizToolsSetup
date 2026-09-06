namespace OrbitHub.Data.Repositories.IndexingManagement.Models;

public class InsertOrGetXmlFileElementSearchInput
{
    public long IndexingXmlFileElementId { get; set; }
    public string ElementValue { get; set; } = default!;
    public string? UserId { get; set; }
}