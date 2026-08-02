using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServiceHubEnterprise.Data.Entities;

[Table("TestSuites")]
public class TestSuiteEntity
{
    [Key, Column("Name"), Required]
    public string Name { get; set; } = "";

    [Column("TotalCases")]
    public int TotalCases { get; set; }

    [Column("PassingCases")]
    public int PassingCases { get; set; }

    [Column("TotalFiles")]
    public int TotalFiles { get; set; }
}