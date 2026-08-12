using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServiceHubEnterprise.Data.Entities;

[Table("WsdlRecords")]
public class WsdlRecordEntity
{
    [Key, Column("Id"), Required]
    public string Id { get; set; } = "";

    [Column("AppId"), Required]
    public string AppId { get; set; } = "";

    [Column("AppName"), Required]
    public string AppName { get; set; } = "";

    [Column("SourceType"), Required]
    public string SourceType { get; set; } = "url";

    [Column("SourceUrl"), Required]
    public string SourceUrl { get; set; } = "";

    [Column("UploadedBy"), Required]
    public string UploadedBy { get; set; } = "";

    [Column("UploadedAt"), Required]
    public string UploadedAt { get; set; } = "";

    [Column("Status")]
    public string Status { get; set; } = "synced";

    [Column("WsdlContentKey")]
    public string? WsdlContentKey { get; set; }
}