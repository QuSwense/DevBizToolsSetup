using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServiceHubEnterprise.Data.Entities;

[Table("SoapParsedFields")]
public class SoapParsedFieldEntity
{
    [Key, Column("Id"), Required]
    public string Id { get; set; } = "";

    [Column("ExecutionFileId"), Required]
    public string ExecutionFileId { get; set; } = "";

    [Column("Name"), Required]
    public string Name { get; set; } = "";

    [Column("Source"), Required]
    public string Source { get; set; } = "";

    [Column("Path"), Required]
    public string Path { get; set; } = "";

    [Column("Value")]
    public string? Value { get; set; }

    [Column("IsEmbedded")]
    public bool IsEmbedded { get; set; }

    [Column("DecodedPreview")]
    public string? DecodedPreview { get; set; }
}