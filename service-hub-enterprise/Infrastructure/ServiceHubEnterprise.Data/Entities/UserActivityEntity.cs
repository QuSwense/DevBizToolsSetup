using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServiceHubEnterprise.Data.Entities;

[Table("UserActivity")]
public class UserActivityEntity
{
    [Key, Column("Id"), Required]
    public string Id { get; set; } = "";

    [Column("UserName"), Required]
    public string UserName { get; set; } = "";

    [Column("Action"), Required]
    public string Action { get; set; } = "";

    [Column("Timestamp"), Required]
    public string Timestamp { get; set; } = "";
}