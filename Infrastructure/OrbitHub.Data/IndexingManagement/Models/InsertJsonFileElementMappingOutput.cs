namespace OrbitHub.Data.IndexingManagement.Models;

public class InsertJsonFileElementMappingOutput
{
    public long Id { get; set; }
    public int? RequestFileId { get; set; }
    public int? ResponseFileId { get; set; }
    public long IndexingJsonFileElementSearchId { get; set; }
    public bool IsNew { get; set; }
}