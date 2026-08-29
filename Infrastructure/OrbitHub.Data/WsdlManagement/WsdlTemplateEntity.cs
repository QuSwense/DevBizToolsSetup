using LinqToDB.Mapping;

namespace OrbitHub.Data.WsdlManagement;

[Table("WsdlTemplates")]
public partial class WsdlTemplateEntity
{
    [Column("Id", IsPrimaryKey = true, CanBeNull = false)]
    public string Id { get; set; } = null!;
    [Column("Name", CanBeNull = false)]
    public string Name { get; set; } = null!;
    [Column("Description")]
    public string? Description { get; set; }
    [Column("Content")]
    public string? Content { get; set; }
    [Column("ExtendsTemplateId")]
    public string? ExtendsTemplateId { get; set; }
    [Column("Variables")]
    public string? Variables { get; set; }
    [Column("CreatedBy", CanBeNull = false)]
    public string CreatedBy { get; set; } = null!;
    [Column("CreatedAt", CanBeNull = false)]
    public string CreatedAt { get; set; } = null!;
    [Column("UpdatedBy")]
    public string? UpdatedBy { get; set; }
    [Column("UpdatedAt")]
    public string? UpdatedAt { get; set; }
}
