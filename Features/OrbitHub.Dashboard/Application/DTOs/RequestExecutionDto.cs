namespace OrbitHub.Dashboard.Application.DTOs;

/// <summary>
/// Data transfer object for a request-file execution attempt (REST or SOAP).
/// </summary>
public sealed class RequestExecutionDto
{
    public string Id { get; set; } = string.Empty;
    public string AppName { get; set; } = string.Empty;
    public string AppType { get; set; } = string.Empty;
    public string FileName { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string ExecutedAt { get; set; } = string.Empty;
    public int DurationMs { get; set; }
    public string TriggeredBy { get; set; } = string.Empty;
}
