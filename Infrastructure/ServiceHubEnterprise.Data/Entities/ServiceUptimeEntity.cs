using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServiceHubEnterprise.Data.Entities;

[Table("ServiceUptime")]
public class ServiceUptimeEntity
{
    [Key, Column("Id"), Required]
    public string Id { get; set; } = "";

    [Column("ServiceName"), Required]
    public string ServiceName { get; set; } = "";

    [Column("Timestamp"), Required]
    public string Timestamp { get; set; } = "";

    [Column("Status"), Required]
    public string Status { get; set; } = "";
}