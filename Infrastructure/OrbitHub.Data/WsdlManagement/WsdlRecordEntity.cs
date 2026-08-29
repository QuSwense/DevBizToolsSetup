using LinqToDB.Mapping;

namespace OrbitHub.Data.WsdlManagement;

[Table("WsdlRecords")]
public partial class WsdlRecordEntity
{
    [Column("Id", IsPrimaryKey = true, CanBeNull = false)]
    public string Id { get; set; } = null!;
    [Column("AppId", CanBeNull = false)]
    public string AppId { get; set; } = null!;
    [Column("AppName", CanBeNull = false)]
    public string AppName { get; set; } = null!;
    [Column("SourceType", CanBeNull = false)]
    public string SourceType { get; set; } = null!;
    [Column("SourceUrl")]
    public string? SourceUrl { get; set; }
    [Column("UploadedBy", CanBeNull = false)]
    public string UploadedBy { get; set; } = null!;
    [Column("UploadedAt", CanBeNull = false)]
    public string UploadedAt { get; set; } = null!;
    [Column("Status", CanBeNull = false)]
    public string Status { get; set; } = null!;
    [Column("WsdlContentKey")]
    public string? WsdlContentKey { get; set; }
}
