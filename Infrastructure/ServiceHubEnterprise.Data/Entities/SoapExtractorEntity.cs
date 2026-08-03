using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServiceHubEnterprise.Data.Entities;

[Table("SoapExtractors")]
public class SoapExtractorEntity
{
    [Key, Column("Id"), Required]
    public string Id { get; set; } = "";

    [Column("TestCaseId"), Required]
    public string TestCaseId { get; set; } = "";

    [Column("Name"), Required]
    public string Name { get; set; } = "";

    [Column("Source")]
    public string Source { get; set; } = "response";

    [Column("Type")]
    public string Type { get; set; } = "xpath";

    [Column("Path"), Required]
    public string Path { get; set; } = "";

    [Column("ExpectedValue")]
    public string? ExpectedValue { get; set; }
}