using LinqToDB.Mapping;

namespace OrbitHub.Data.SoapManagement;

[Table("SoapParsedFields")]
public partial class SoapParsedFieldEntity
{
    [Column("Id", IsPrimaryKey = true, CanBeNull = false)]
    public string Id { get; set; } = null!;
    [Column("ExecutionFileId", CanBeNull = false)]
    public string ExecutionFileId { get; set; } = null!;
    [Column("Name", CanBeNull = false)]
    public string Name { get; set; } = null!;
    [Column("Source", CanBeNull = false)]
    public string Source { get; set; } = null!;
    [Column("Path", CanBeNull = false)]
    public string Path { get; set; } = null!;
    [Column("Value")]
    public string? Value { get; set; }
    [Column("IsEmbedded")]
    public bool IsEmbedded { get; set; }
    [Column("DecodedPreview")]
    public string? DecodedPreview { get; set; }
}
