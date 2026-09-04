namespace ServiceHub.SoapEngine.Core.Models.Inputs;

/// <summary>
/// Payload contract for updating application metadata.
/// </summary>
public class EditApplicationInput
{
    public required int AppId { get; set; }
    public required string AppName { get; set; }
    public required string BaseUrl { get; set; }
    public string? WsdlRelativeUrl { get; set; }
    public string? HealthcheckRelativeUrl { get; set; }
    public string? Description { get; set; }
    public required string UpdatedBy { get; set; }
    public string? Comment { get; set; }
}