using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServiceHubEnterprise.Data.Entities;

[Table("SoapExtractionResults")]
public class SoapExtractionResultEntity
{
    [Key, Column("Id"), Required]
    public string Id { get; set; } = "";

    [Column("ExecutionFileId"), Required]
    public string ExecutionFileId { get; set; } = "";

    [Column("ExtractorId"), Required]
    public string ExtractorId { get; set; } = "";

    [Column("Name"), Required]
    public string Name { get; set; } = "";

    [Column("Source"), Required]
    public string Source { get; set; } = "";

    [Column("Type"), Required]
    public string Type { get; set; } = "";

    [Column("Path"), Required]
    public string Path { get; set; } = "";

    [Column("Value")]
    public string? Value { get; set; }

    [Column("Expected")]
    public string? Expected { get; set; }

    [Column("Passed")]
    public bool? Passed { get; set; }
}