namespace OrbitHub.Data.IndexingManagement.Models;

public class InsertXmlFileElementMappingInput
{
    public long IndexingXmlFileElementSearchId { get; set; }
    public int? RequestFileId { get; set; }
    public int? ResponseFileId { get; set; }
    public string? UserId { get; set; }
}