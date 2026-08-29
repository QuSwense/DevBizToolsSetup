using LinqToDB.Mapping;

namespace OrbitHub.Data.SoapManagement;

[Table("SoapExecutionLogs")]
public partial class SoapExecutionLogEntity
{
    [Column("Id", IsPrimaryKey = true, CanBeNull = false)]
    public string Id { get; set; } = null!;
    [Column("ExecutionFileId", CanBeNull = false)]
    public string ExecutionFileId { get; set; } = null!;
    [Column("Timestamp", CanBeNull = false)]
    public string Timestamp { get; set; } = null!;
    [Column("Type", CanBeNull = false)]
    public string Type { get; set; } = null!;
    [Column("Message", CanBeNull = false)]
    public string Message { get; set; } = null!;
}
