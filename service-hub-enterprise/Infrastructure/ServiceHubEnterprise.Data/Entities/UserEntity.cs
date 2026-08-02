using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServiceHubEnterprise.Data.Entities;

[Table("Users")]
public class UserEntity
{
    [Key, Column("Name"), Required]
    public string Name { get; set; } = "";

    [Column("Role")]
    public string Role { get; set; } = "User";
}