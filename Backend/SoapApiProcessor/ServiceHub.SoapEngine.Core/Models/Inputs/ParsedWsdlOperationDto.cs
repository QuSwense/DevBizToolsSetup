namespace ServiceHub.SoapEngine.Core.Models.Inputs;

public class ParsedWsdlOperationDto
{
    public required string OperationName { get; set; }
    public string? SoapAction { get; set; }
    public string? InputRootElementName { get; set; }
    public string? OutputRootElementName { get; set; }
    public string? TargetNamespace { get; set; }  // NEW
}