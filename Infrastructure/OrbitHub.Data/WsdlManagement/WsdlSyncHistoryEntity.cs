using LinqToDB.Mapping;

namespace OrbitHub.Data.WsdlManagement;

[Table("WsdlSyncHistory")]
public partial class WsdlSyncHistoryEntity
{
    [Column("Id", IsPrimaryKey = true, CanBeNull = false)]
    public string Id { get; set; } = null!;
    [Column("AppId", CanBeNull = false)]
    public string AppId { get; set; } = null!;
    [Column("AppName", CanBeNull = false)]
    public string AppName { get; set; } = null!;
    [Column("SyncRecordId", CanBeNull = false)]
    public string SyncRecordId { get; set; } = null!;
    [Column("Date", CanBeNull = false)]
    public string Date { get; set; } = null!;
    [Column("Status", CanBeNull = false)]
    public string Status { get; set; } = null!;
    [Column("Details")]
    public string? Details { get; set; }
}
