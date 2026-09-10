namespace OrbitHub.Data.IndexingManagement.Models;

public class InsertJsonFileElementMappingInput
{
    public long IndexingJsonFileElementSearchId { get; set; }
    public int? RequestFileId { get; set; }
    public int? ResponseFileId { get; set; }
    public string? UserId { get; set; }
}