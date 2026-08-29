using LinqToDB.Mapping;

namespace OrbitHub.Data.RestManagement;

[Table("RestRequestFiles")]
public partial class RestRequestFileEntity
{
    [Column("Id", IsPrimaryKey = true, CanBeNull = false)]
    public string Id { get; set; } = null!;
    [Column("FileName", CanBeNull = false)]
    public string FileName { get; set; } = null!;
    [Column("AppName", CanBeNull = false)]
    public string AppName { get; set; } = null!;
    [Column("ApiPath", CanBeNull = false)]
    public string ApiPath { get; set; } = null!;
    [Column("Verb", CanBeNull = false)]
    public string Verb { get; set; } = null!;
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
    [Column("Content")]
    public string? Content { get; set; }
}
