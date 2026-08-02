using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServiceHubEnterprise.Data.Entities;

[Table("SoapExecutionLogs")]
public class SoapExecutionLogEntity
{
    [Key, Column("Id"), Required]
    public string Id { get; set; } = "";

    [Column("ExecutionFileId"), Required]
    public string ExecutionFileId { get; set; } = "";

    [Column("Timestamp"), Required]
    public string Timestamp { get; set; } = "";

    [Column("Type"), Required]
    public string Type { get; set; } = "info";

    [Column("Message"), Required]
    public string Message { get; set; } = "";
}