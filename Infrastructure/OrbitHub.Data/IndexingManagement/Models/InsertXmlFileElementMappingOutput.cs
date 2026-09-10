namespace OrbitHub.Data.IndexingManagement.Models;

public class InsertXmlFileElementMappingOutput
{
    public long Id { get; set; }
    public int? RequestFileId { get; set; }
    public int? ResponseFileId { get; set; }
    public long IndexingXmlFileElementSearchId { get; set; }
    public bool IsNew { get; set; }
}