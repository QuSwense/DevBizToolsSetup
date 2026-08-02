using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServiceHubEnterprise.Data.Entities;

[Table("SoapApis")]
public class SoapApiEntity
{
    [Key, Column("Id"), Required]
    public string Id { get; set; } = "";

    [Column("AppId"), Required]
    public string AppId { get; set; } = "";

    [Column("Name"), Required]
    public string Name { get; set; } = "";

    [Column("Description")]
    public string Description { get; set; } = "";
}