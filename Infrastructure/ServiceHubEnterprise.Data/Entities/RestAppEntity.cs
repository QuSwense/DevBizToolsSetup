using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServiceHubEnterprise.Data.Entities;

[Table("RestApps")]
public class RestAppEntity
{
    [Key, Column("Id"), Required]
    public string Id { get; set; } = "";

    [Column("Name"), Required]
    public string Name { get; set; } = "";

    [Column("BaseUrl"), Required]
    public string BaseUrl { get; set; } = "";

    [Column("Description")]
    public string Description { get; set; } = "";

    [Column("Status")]
    public string Status { get; set; } = "enabled";

    [Column("CreatedBy"), Required]
    public string CreatedBy { get; set; } = "";

    [Column("CreatedAt"), Required]
    public string CreatedAt { get; set; } = "";

    [Column("UpdatedBy")]
    public string? UpdatedBy { get; set; }

    [Column("UpdatedAt")]
    public string? UpdatedAt { get; set; }

    [Column("ApisCount")]
    public int ApisCount { get; set; }
}