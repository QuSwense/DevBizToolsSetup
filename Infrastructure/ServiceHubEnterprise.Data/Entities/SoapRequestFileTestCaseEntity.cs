using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ServiceHubEnterprise.Data.Entities;

/// <summary>
/// Junction table linking SoapRequestFiles to SoapTestCases (many-to-many).
/// Replaces the denormalized TestCaseIds JSON array on SoapRequestFiles.
/// </summary>
[Table("SoapRequestFileTestCases")]
public class SoapRequestFileTestCaseEntity
{
    [Column("FileId"), Required]
    public string FileId { get; set; } = "";

    [Column("TestCaseId"), Required]
    public string TestCaseId { get; set; } = "";
}