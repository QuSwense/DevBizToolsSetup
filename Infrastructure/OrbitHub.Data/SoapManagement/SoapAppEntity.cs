using LinqToDB.Mapping;

namespace OrbitHub.Data.SoapManagement;

[Table("SoapApps")]
public partial class SoapAppEntity
{
    [Column("Id", IsPrimaryKey = true, CanBeNull = false)]
    public string Id { get; set; } = null!;
    [Column("Name", CanBeNull = false)]
    public string Name { get; set; } = null!;
    [Column("BaseUrl", CanBeNull = false)]
    public string BaseUrl { get; set; } = null!;
    [Column("WsdlPath", CanBeNull = false)]
    public string WsdlPath { get; set; } = null!;
    [Column("Description")]
    public string? Description { get; set; }
    [Column("Status", CanBeNull = false)]
    public string Status { get; set; } = null!;
    [Column("CreatedBy", CanBeNull = false)]
    public string CreatedBy { get; set; } = null!;
    [Column("CreatedAt", CanBeNull = false)]
    public string CreatedAt { get; set; } = null!;
    [Column("UpdatedBy")]
    public string? UpdatedBy { get; set; }
    [Column("UpdatedAt")]
    public string? UpdatedAt { get; set; }
    [Column("AuthType")]
    public string? AuthType { get; set; }
    [Column("AuthUsername")]
    public string? AuthUsername { get; set; }
    [Column("AuthPassword")]
    public string? AuthPassword { get; set; }
    [Column("AuthKeyName")]
    public string? AuthKeyName { get; set; }
    [Column("AuthKeyValue")]
    public string? AuthKeyValue { get; set; }
    [Column("AuthToken")]
    public string? AuthToken { get; set; }
    [Column("AuthDomain")]
    public string? AuthDomain { get; set; }

    #region Associations
    [Association(ThisKey = nameof(Id), OtherKey = nameof(SoapApiEntity.AppId))]
    public IEnumerable<SoapApiEntity> Apis { get; set; } = null!;
    #endregion
}
