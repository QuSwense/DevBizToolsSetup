namespace ServiceHubEnterprise.SoapApplications.Models;

/// <summary>
/// A specific version snapshot of a WSDL sync record.
/// </summary>
public class WsdlVersionEntry
{
    public string Id { get; set; } = "";
    public string SyncRecordId { get; set; } = "";
    public int VersionNumber { get; set; } = 1;
    public string Label { get; set; } = "v1";
    public string UploadedBy { get; set; } = "";
    public string UploadedAt { get; set; } = "";
    public string Status { get; set; } = "active"; // "active" | "archived"
    public string Notes { get; set; } = "";
}
