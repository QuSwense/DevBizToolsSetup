namespace OrbitHub.SoapEngine.Core.Models.Inputs;

/// <summary>
/// Base class carrying common SOAP operation metadata fields shared across
/// manual operation creation and save-operation input models.
/// </summary>
public class OperationMetadataInputModel
{
    public required string OperationName { get; set; }
    public string? Description { get; set; }
    public string? SoapAction { get; set; }
    public string? InputRootElementName { get; set; }
    public string? OutputRootElementName { get; set; }
    public string? TargetNamespace { get; set; }
    public string? RawXsdSchema { get; set; }
}