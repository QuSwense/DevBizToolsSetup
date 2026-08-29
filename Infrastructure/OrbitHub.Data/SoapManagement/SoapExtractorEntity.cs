using LinqToDB.Mapping;

namespace OrbitHub.Data.SoapManagement;

[Table("SoapExtractors")]
public partial class SoapExtractorEntity
{
    [Column("Id", IsPrimaryKey = true, CanBeNull = false)]
    public string Id { get; set; } = null!;
    [Column("TestCaseId", CanBeNull = false)]
    public string TestCaseId { get; set; } = null!;
    [Column("Name", CanBeNull = false)]
    public string Name { get; set; } = null!;
    [Column("Source", CanBeNull = false)]
    public string Source { get; set; } = null!;
    [Column("Type", CanBeNull = false)]
    public string Type { get; set; } = null!;
    [Column("Path", CanBeNull = false)]
    public string Path { get; set; } = null!;
    [Column("ExpectedValue")]
    public string? ExpectedValue { get; set; }
}
