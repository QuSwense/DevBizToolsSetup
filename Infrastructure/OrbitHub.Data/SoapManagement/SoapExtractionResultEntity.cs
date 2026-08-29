using LinqToDB.Mapping;

namespace OrbitHub.Data.SoapManagement;

[Table("SoapExtractionResults")]
public partial class SoapExtractionResultEntity
{
    [Column("Id", IsPrimaryKey = true, CanBeNull = false)]
    public string Id { get; set; } = null!;
    [Column("ExecutionFileId", CanBeNull = false)]
    public string ExecutionFileId { get; set; } = null!;
    [Column("ExtractorId", CanBeNull = false)]
    public string ExtractorId { get; set; } = null!;
    [Column("Name", CanBeNull = false)]
    public string Name { get; set; } = null!;
    [Column("Source", CanBeNull = false)]
    public string Source { get; set; } = null!;
    [Column("Type", CanBeNull = false)]
    public string Type { get; set; } = null!;
    [Column("Path", CanBeNull = false)]
    public string Path { get; set; } = null!;
    [Column("Value")]
    public string? Value { get; set; }
    [Column("Expected")]
    public string? Expected { get; set; }
    [Column("Passed")]
    public bool? Passed { get; set; }
}
