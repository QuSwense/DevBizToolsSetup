namespace ServiceHubEnterprise.Dashboard.Application.DTOs;

/// <summary>
/// Data transfer object for a request file summary.
/// </summary>
public sealed class RequestFileDto
{
    public string FileName { get; set; } = string.Empty;
    public string AppName { get; set; } = string.Empty;
    public string Verb { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string CreatedBy { get; set; } = string.Empty;
}
