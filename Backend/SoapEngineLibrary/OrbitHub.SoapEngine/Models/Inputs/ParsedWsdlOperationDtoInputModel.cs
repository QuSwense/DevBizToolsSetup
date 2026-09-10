namespace OrbitHub.SoapEngine.Core.Models.Inputs;

public class ParsedWsdlOperationDtoInputModel
{
    public required string OperationName { get; set; }
    public string? SoapAction { get; set; }
    public string? InputRootElementName { get; set; }
    public string? OutputRootElementName { get; set; }
    public string? TargetNamespace { get; set; }  // NEW
}