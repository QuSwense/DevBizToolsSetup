namespace ServiceHub.SoapEngine.Core.Models.Inputs;

/// <summary>
/// Input model to manually define a SOAP Operation without a WSDL file.
/// </summary>
public class CreateManualOperationInput
{
    public required int AppId { get; set; }
    public required string OperationName { get; set; }
    public string? Description { get; set; }
    public string? SoapAction { get; set; }
    public required string InputRootElementName { get; set; }
    public required string OutputRootElementName { get; set; }
    public required string TargetNamespace { get; set; }
    public string? RawXsdSchema { get; set; } // Optional manual XSD validation schema
    public required string CreatedBy { get; set; }
}