using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServiceHubEnterprise.Data.Entities;

[Table("SoapExecutionFiles")]
public class SoapExecutionFileEntity
{
    [Key, Column("Id"), Required]
    public string Id { get; set; } = "";

    [Column("GroupId"), Required]
    public string GroupId { get; set; } = "";

    [Column("FileName"), Required]
    public string FileName { get; set; } = "";

    [Column("AppName"), Required]
    public string AppName { get; set; } = "";

    [Column("AppId")]
    public string? AppId { get; set; }

    [Column("Operation"), Required]
    public string Operation { get; set; } = "";

    [Column("Status")]
    public string Status { get; set; } = "queued";

    [Column("Stage")]
    public int Stage { get; set; }

    [Column("StagesCompleted")]
    public int StagesCompleted { get; set; }

    [Column("StagesTotal")]
    public int StagesTotal { get; set; } = 7;

    [Column("RequestContent")]
    public string? RequestContent { get; set; }

    [Column("ResponseContent")]
    public string? ResponseContent { get; set; }

    [Column("ResponseMimeType")]
    public string? ResponseMimeType { get; set; }

    public List<SoapExecutionLogEntity> Logs { get; set; } = new();
    public List<SoapParsedFieldEntity> ParsedFields { get; set; } = new();
    public List<SoapExtractionResultEntity> Extractions { get; set; } = new();
}