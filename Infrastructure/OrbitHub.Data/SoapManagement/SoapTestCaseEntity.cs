using LinqToDB.Mapping;

namespace OrbitHub.Data.SoapManagement;

[Table("SoapTestCases")]
public partial class SoapTestCaseEntity
{
    [Column("Id", IsPrimaryKey = true, CanBeNull = false)]
    public string Id { get; set; } = null!;
    [Column("Name", CanBeNull = false)]
    public string Name { get; set; } = null!;
    [Column("Description")]
    public string? Description { get; set; }
    [Column("AppName", CanBeNull = false)]
    public string AppName { get; set; } = null!;
    [Column("FileName", CanBeNull = false)]
    public string FileName { get; set; } = null!;
    [Column("Enabled")]
    public bool Enabled { get; set; }
    [Column("CreatedBy", CanBeNull = false)]
    public string CreatedBy { get; set; } = null!;
    [Column("CreatedAt", CanBeNull = false)]
    public string CreatedAt { get; set; } = null!;
    [Column("UpdatedBy")]
    public string? UpdatedBy { get; set; }
    [Column("UpdatedAt")]
    public string? UpdatedAt { get; set; }

    #region Associations
    [Association(ThisKey = nameof(Id), OtherKey = nameof(SoapExtractorEntity.TestCaseId))]
    public IEnumerable<SoapExtractorEntity> Extractors { get; set; } = null!;
    #endregion
}
