using LinqToDB.Mapping;

namespace OrbitHub.Data.SoapManagement;

[Table("SoapExecutionGroups")]
public partial class SoapExecutionGroupEntity
{
    [Column("Id", IsPrimaryKey = true, CanBeNull = false)]
    public string Id { get; set; } = null!;
    [Column("StartedAt", CanBeNull = false)]
    public string StartedAt { get; set; } = null!;
    [Column("FinishedAt")]
    public string? FinishedAt { get; set; }
    [Column("TriggeredBy", CanBeNull = false)]
    public string TriggeredBy { get; set; } = null!;
    [Column("Status", CanBeNull = false)]
    public string Status { get; set; } = null!;
    [Column("DurationMs")]
    public long? DurationMs { get; set; }

    #region Associations
    [Association(ThisKey = nameof(Id), OtherKey = nameof(SoapExecutionFileEntity.GroupId))]
    public IEnumerable<SoapExecutionFileEntity> Files { get; set; } = null!;
    #endregion
}
