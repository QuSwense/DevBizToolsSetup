namespace ServiceHub.SoapEngine.Core.Models.Inputs;

/// <summary>
/// Base class carrying common application metadata fields shared across
/// create, update, and registration input models.
/// </summary>
public class ApplicationMetadata
{
    public required string AppName { get; set; }
    public required string BaseUrl { get; set; }
    public string? WsdlRelativeUrl { get; set; }
    public string? HealthcheckRelativeUrl { get; set; }
    public string? Description { get; set; }
}