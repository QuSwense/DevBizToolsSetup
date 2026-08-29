namespace OrbitHub.Dashboard.Core.Entities;

/// <summary>
/// Represents a WSDL sync record for a SOAP application.
/// </summary>
public sealed class WsdlRecordEntity
{
    public string Id { get; set; } = string.Empty;
    public string AppId { get; set; } = string.Empty;
    public string AppName { get; set; } = string.Empty;
    public string SourceType { get; set; } = string.Empty;
    public string UploadedBy { get; set; } = string.Empty;
    public string UploadedAt { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public int VersionCount { get; set; }
}
