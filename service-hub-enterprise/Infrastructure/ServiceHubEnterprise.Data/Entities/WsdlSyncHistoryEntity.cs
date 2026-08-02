using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServiceHubEnterprise.Data.Entities;

[Table("WsdlSyncHistory")]
public class WsdlSyncHistoryEntity
{
    [Key, Column("Id"), Required]
    public string Id { get; set; } = "";

    [Column("AppId"), Required]
    public string AppId { get; set; } = "";

    [Column("AppName"), Required]
    public string AppName { get; set; } = "";

    [Column("SyncRecordId"), Required]
    public string SyncRecordId { get; set; } = "";

    [Column("Date"), Required]
    public string Date { get; set; } = "";

    [Column("Status"), Required]
    public string Status { get; set; } = "";

    [Column("Details")]
    public string? Details { get; set; }
}