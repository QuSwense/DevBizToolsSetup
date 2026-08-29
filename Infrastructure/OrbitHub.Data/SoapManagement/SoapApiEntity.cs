using LinqToDB.Mapping;

namespace OrbitHub.Data.SoapManagement;

[Table("SoapApis")]
public partial class SoapApiEntity
{
    [Column("Id", IsPrimaryKey = true, IsIdentity = true, SkipOnInsert = true, SkipOnUpdate = true)]
    public int Id { get; set; }
    [Column("AppId", CanBeNull = false)]
    public string AppId { get; set; } = null!;
    [Column("Name", CanBeNull = false)]
    public string Name { get; set; } = null!;
    [Column("Description")]
    public string? Description { get; set; }

    #region Associations
    [Association(CanBeNull = false, ThisKey = nameof(AppId), OtherKey = nameof(SoapAppEntity.Id))]
    public SoapAppEntity App { get; set; } = null!;
    #endregion
}
