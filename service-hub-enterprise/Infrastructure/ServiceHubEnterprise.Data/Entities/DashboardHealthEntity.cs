using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServiceHubEnterprise.Data.Entities;

[Table("DashboardHealth")]
public class DashboardHealthEntity
{
    [Key, Column("Name"), Required]
    public string Name { get; set; } = "";

    [Column("Status"), Required]
    public string Status { get; set; } = "";
}