using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServiceHubEnterprise.Data.Entities;

[Table("DashboardMetrics")]
public class DashboardMetricEntity
{
    [Key, Column("Id"), Required]
    public string Id { get; set; } = "";

    [Column("Name"), Required]
    public string Name { get; set; } = "";

    [Column("Value")]
    public int Value { get; set; }
}