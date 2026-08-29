using LinqToDB.Mapping;

namespace OrbitHub.Data.WsdlManagement;

[Table("WsdlVersions")]
public partial class WsdlVersionEntity
{
    [Column("Id", IsPrimaryKey = true, CanBeNull = false)]
    public string Id { get; set; } = null!;
    [Column("SyncRecordId", CanBeNull = false)]
    public string SyncRecordId { get; set; } = null!;
    [Column("VersionNumber")]
    public int VersionNumber { get; set; }
    [Column("Label", CanBeNull = false)]
    public string Label { get; set; } = null!;
    [Column("UploadedBy", CanBeNull = false)]
    public string UploadedBy { get; set; } = null!;
    [Column("UploadedAt", CanBeNull = false)]
    public string UploadedAt { get; set; } = null!;
    [Column("Status", CanBeNull = false)]
    public string Status { get; set; } = null!;
    [Column("Notes")]
    public string? Notes { get; set; }
    [Column("Content", CanBeNull = false)]
    public string Content { get; set; } = "";
}
