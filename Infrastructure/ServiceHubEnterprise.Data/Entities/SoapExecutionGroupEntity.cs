using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServiceHubEnterprise.Data.Entities;

[Table("SoapExecutionGroups")]
public class SoapExecutionGroupEntity
{
    [Key, Column("Id"), Required]
    public string Id { get; set; } = "";

    [Column("StartedAt"), Required]
    public string StartedAt { get; set; } = "";

    [Column("FinishedAt")]
    public string? FinishedAt { get; set; }

    [Column("TriggeredBy"), Required]
    public string TriggeredBy { get; set; } = "";

    [Column("Status"), Required]
    public string Status { get; set; } = "running";

    [Column("DurationMs")]
    public long? DurationMs { get; set; }

    public List<SoapExecutionFileEntity> Files { get; set; } = new();
}