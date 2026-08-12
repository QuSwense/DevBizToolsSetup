using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServiceHubEnterprise.Data.Entities;

[Table("SoapRequestFiles")]
public class SoapRequestFileEntity
{
    [Key, Column("Id"), Required]
    public string Id { get; set; } = "";

    [Column("FileName"), Required]
    public string FileName { get; set; } = "";

    [Column("AppName"), Required]
    public string AppName { get; set; } = "";

    [Column("ApiPath"), Required]
    public string ApiPath { get; set; } = "";

    [Column("Verb")]
    public string Verb { get; set; } = "POST";

    [Column("Description")]
    public string Description { get; set; } = "";

    [Column("Status")]
    public string Status { get; set; } = "active";

    [Column("CreatedBy"), Required]
    public string CreatedBy { get; set; } = "";

    [Column("CreatedAt"), Required]
    public string CreatedAt { get; set; } = "";

    [Column("UpdatedBy")]
    public string? UpdatedBy { get; set; }

    [Column("UpdatedAt")]
    public string? UpdatedAt { get; set; }

    [Column("Content")]
    public string? Content { get; set; }

    [Column("AppId")]
    public string? AppId { get; set; }
}