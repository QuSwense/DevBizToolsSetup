namespace OrbitHub.Dashboard.Core.Entities;

/// <summary>
/// Represents a request file (e.g., a SOAP envelope) tracked on the dashboard.
/// </summary>
public sealed class RequestFileEntity
{
    public string FileName { get; set; } = string.Empty;
    public string AppName { get; set; } = string.Empty;
    public string Verb { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string CreatedBy { get; set; } = string.Empty;
}
