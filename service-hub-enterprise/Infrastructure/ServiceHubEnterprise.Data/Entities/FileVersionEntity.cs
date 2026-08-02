using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServiceHubEnterprise.Data.Entities;

[Table("FileVersions")]
public class FileVersionEntity
{
    [Key, Column("Id"), Required]
    public string Id { get; set; } = "";

    [Column("SourceType"), Required]
    public string SourceType { get; set; } = "";

    [Column("SourceId"), Required]
    public string SourceId { get; set; } = "";

    [Column("FileName"), Required]
    public string FileName { get; set; } = "";

    [Column("Content"), Required]
    public string Content { get; set; } = "";

    [Column("SavedBy"), Required]
    public string SavedBy { get; set; } = "";

    [Column("SavedAt"), Required]
    public string SavedAt { get; set; } = "";

    [Column("VersionNumber")]
    public int VersionNumber { get; set; }
}