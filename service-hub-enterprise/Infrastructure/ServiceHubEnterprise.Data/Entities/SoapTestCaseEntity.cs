using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServiceHubEnterprise.Data.Entities;

[Table("SoapTestCases")]
public class SoapTestCaseEntity
{
    [Key, Column("Id"), Required]
    public string Id { get; set; } = "";

    [Column("Name"), Required]
    public string Name { get; set; } = "";

    [Column("Description")]
    public string Description { get; set; } = "";

    [Column("AppName"), Required]
    public string AppName { get; set; } = "";

    [Column("FileName"), Required]
    public string FileName { get; set; } = "";

    [Column("Enabled")]
    public bool Enabled { get; set; } = true;

    [Column("CreatedBy"), Required]
    public string CreatedBy { get; set; } = "";

    [Column("CreatedAt"), Required]
    public string CreatedAt { get; set; } = "";

    [Column("UpdatedBy")]
    public string? UpdatedBy { get; set; }

    [Column("UpdatedAt")]
    public string? UpdatedAt { get; set; }

    public List<SoapExtractorEntity> Extractors { get; set; } = new();
}