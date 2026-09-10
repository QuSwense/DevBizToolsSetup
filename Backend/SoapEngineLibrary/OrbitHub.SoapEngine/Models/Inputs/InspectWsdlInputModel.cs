namespace ServiceHub.SoapEngine.Core.Models.Inputs;

/// <summary>
/// Request input to inspect/fetch operations from a WSDL URL or uploaded WSDL Stream prior to saving.
/// </summary>
public class InspectWsdlInput
{
    public string? WsdlUrl { get; set; }
    public Stream? WsdlFileStream { get; set; }
}
