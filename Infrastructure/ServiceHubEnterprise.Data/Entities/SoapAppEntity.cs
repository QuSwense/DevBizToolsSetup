using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServiceHubEnterprise.Data.Entities;

[Table("SoapApps")]
public class SoapAppEntity
{
    [Key, Column("Id"), Required]
    public string Id { get; set; } = "";

    [Column("Name"), Required]
    public string Name { get; set; } = "";

    [Column("BaseUrl"), Required]
    public string BaseUrl { get; set; } = "";

    [Column("WsdlPath")]
    public string WsdlPath { get; set; } = "";

    [Column("Description")]
    public string Description { get; set; } = "";

    [Column("Status"), Required]
    public string Status { get; set; } = "enabled";

    [Column("CreatedBy"), Required]
    public string CreatedBy { get; set; } = "";

    [Column("UpdatedBy")]
    public string? UpdatedBy { get; set; }

    [Column("CreatedAt"), Required]
    public string CreatedAt { get; set; } = "";

    [Column("UpdatedAt")]
    public string? UpdatedAt { get; set; }

    [Column("AuthType")]
    public string AuthType { get; set; } = "None";

    [Column("AuthUsername")]
    public string? AuthUsername { get; set; }

    [Column("AuthPassword")]
    public string? AuthPassword { get; set; }

    [Column("AuthKeyName")]
    public string? AuthKeyName { get; set; }

    [Column("AuthKeyValue")]
    public string? AuthKeyValue { get; set; }

    [Column("AuthToken")]
    public string? AuthToken { get; set; }

    [Column("AuthDomain")]
    public string? AuthDomain { get; set; }

    public List<SoapApiEntity> Apis { get; set; } = new();
}