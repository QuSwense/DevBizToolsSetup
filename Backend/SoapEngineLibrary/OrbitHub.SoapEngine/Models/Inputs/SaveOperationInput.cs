namespace ServiceHub.SoapEngine.Core.Models.Inputs;

using ServiceHub.SoapEngine.Core.Enums;

/// <summary>
/// Represents a single SOAP operation definition supplied via UI.
/// </summary>
public class SaveOperationInput
{
    public int? Id { get; set; }
    public required string OperationName { get; set; }
    public string? Description { get; set; }
    public string? SoapAction { get; set; }
    public string? InputRootElementName { get; set; }
    public string? OutputRootElementName { get; set; }
    public string? TargetNamespace { get; set; }
    public string? RawXsdSchema { get; set; }
    public bool IsActive { get; set; } = true;
}
