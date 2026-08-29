namespace OrbitHub.SoapApplications.Models;

/// <summary>
/// Represents a WSDL sync record linking a SOAP application to its WSDL source.
/// </summary>
public class WsdlSyncRecord
{
    public string Id { get; set; } = "";
    public string AppId { get; set; } = "";
    public string AppName { get; set; } = "";
    public string SourceType { get; set; } = "url"; // "url" | "upload"
    public string SourceUrl { get; set; } = "";
    public string UploadedBy { get; set; } = "";
    public string UploadedAt { get; set; } = "";
    public string Status { get; set; } = "synced"; // "synced" | "failed" | "parsing"
    public string WsdlContent { get; set; } = "";
    public string WsdlContentKey { get; set; } = "";
    public int VersionCount { get; set; } = 1;
}
