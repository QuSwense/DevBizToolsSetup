using LinqToDB.Mapping;

namespace OrbitHub.Data.FileVersionManagement;

[Table("FileVersions")]
public partial class FileVersionEntity
{
    [Column("Id", IsPrimaryKey = true, CanBeNull = false)]
    public string Id { get; set; } = null!;
    [Column("SourceType", CanBeNull = false)]
    public string SourceType { get; set; } = null!;
    [Column("SourceId", CanBeNull = false)]
    public string SourceId { get; set; } = null!;
    [Column("FileName", CanBeNull = false)]
    public string FileName { get; set; } = null!;
    [Column("Content")]
    public string? Content { get; set; }
    [Column("SavedBy", CanBeNull = false)]
    public string SavedBy { get; set; } = null!;
    [Column("SavedAt", CanBeNull = false)]
    public string SavedAt { get; set; } = null!;
    [Column("VersionNumber")]
    public int VersionNumber { get; set; }
}
