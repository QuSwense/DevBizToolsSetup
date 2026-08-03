using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServiceHubEnterprise.Data.Entities;

[Table("WsdlTemplates")]
public class WsdlTemplateEntity
{
    [Key, Column("Id"), Required]
    public string Id { get; set; } = "";

    [Column("Name"), Required]
    public string Name { get; set; } = "";

    [Column("Description")]
    public string Description { get; set; } = "";

    [Column("Content"), Required]
    public string Content { get; set; } = "";

    [Column("ExtendsTemplateId")]
    public string? ExtendsTemplateId { get; set; }

    [Column("Variables")]
    public string? Variables { get; set; }

    [Column("CreatedBy"), Required]
    public string CreatedBy { get; set; } = "";

    [Column("CreatedAt"), Required]
    public string CreatedAt { get; set; } = "";

    [Column("UpdatedAt")]
    public string? UpdatedAt { get; set; }

    [Column("UsageCount")]
    public int UsageCount { get; set; }
}