using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServiceHubEnterprise.Data.Entities;

[Table("WsdlVersions")]
public class WsdlVersionEntity
{
    [Key, Column("Id"), Required]
    public string Id { get; set; } = "";

    [Column("SyncRecordId"), Required]
    public string SyncRecordId { get; set; } = "";

    [Column("VersionNumber")]
    public int VersionNumber { get; set; }

    [Column("Label"), Required]
    public string Label { get; set; } = "";

    [Column("UploadedBy"), Required]
    public string UploadedBy { get; set; } = "";

    [Column("UploadedAt"), Required]
    public string UploadedAt { get; set; } = "";

    [Column("Status")]
    public string Status { get; set; } = "active";

    [Column("Notes")]
    public string? Notes { get; set; }

    [Column("Content"), Required]
    public string Content { get; set; } = "";
}