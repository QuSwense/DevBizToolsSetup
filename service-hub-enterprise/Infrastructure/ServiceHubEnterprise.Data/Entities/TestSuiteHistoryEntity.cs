using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServiceHubEnterprise.Data.Entities;

[Table("TestSuiteHistory")]
public class TestSuiteHistoryEntity
{
    [Key, Column("Id"), Required]
    public string Id { get; set; } = "";

    [Column("SuiteName"), Required]
    public string SuiteName { get; set; } = "";

    [Column("ExecutedAt"), Required]
    public string ExecutedAt { get; set; } = "";

    [Column("Status"), Required]
    public string Status { get; set; } = "";

    [Column("TotalCases")]
    public int TotalCases { get; set; }

    [Column("PassingCases")]
    public int PassingCases { get; set; }

    [Column("DurationMs")]
    public int DurationMs { get; set; }
}