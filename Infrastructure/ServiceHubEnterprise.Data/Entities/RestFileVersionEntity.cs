using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServiceHubEnterprise.Data.Entities;

[Table("RestFileVersions")]
public class RestFileVersionEntity
{
    [Key, Column("Id"), Required]
    public string Id { get; set; } = "";

    [Column("FileId"), Required]
    public string FileId { get; set; } = "";

    [Column("FileName"), Required]
    public string FileName { get; set; } = "";

    [Column("AppName"), Required]
    public string AppName { get; set; } = "";

    [Column("Content"), Required]
    public string Content { get; set; } = "";

    [Column("SavedBy"), Required]
    public string SavedBy { get; set; } = "";

    [Column("SavedAt"), Required]
    public string SavedAt { get; set; } = "";

    [Column("VersionNumber")]
    public int VersionNumber { get; set; }

    [Column("Notes")]
    public string? Notes { get; set; }
}