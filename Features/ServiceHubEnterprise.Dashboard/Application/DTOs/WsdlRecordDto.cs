namespace ServiceHubEnterprise.Dashboard.Application.DTOs;

/// <summary>
/// Data transfer object for a WSDL sync record.
/// </summary>
public sealed class WsdlRecordDto
{
    public string AppName { get; set; } = string.Empty;
    public string SourceType { get; set; } = string.Empty;
    public string UploadedAt { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public int VersionCount { get; set; }
}
