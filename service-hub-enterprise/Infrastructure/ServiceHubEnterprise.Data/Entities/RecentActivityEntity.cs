using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServiceHubEnterprise.Data.Entities;

[Table("RecentActivity")]
public class RecentActivityEntity
{
    [Key, Column("Id"), DatabaseGenerated(DatabaseGeneratedOption.Identity)]
    public int Id { get; set; }

    [Column("User"), Required]
    public string User { get; set; } = "";

    [Column("Action"), Required]
    public string Action { get; set; } = "";

    [Column("TimeAgo"), Required]
    public string TimeAgo { get; set; } = "";
}