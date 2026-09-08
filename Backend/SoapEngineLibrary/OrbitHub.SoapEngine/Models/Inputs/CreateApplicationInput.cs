namespace ServiceHub.SoapEngine.Core.Models.Inputs;

/// <summary>
/// Base class for create-type application inputs.
/// Carries the actor identifier and optional direct WSDL stream.
/// </summary>
public class CreateApplicationInput : ApplicationMetadata
{
    public required string CreatedBy { get; set; }
    public Stream? DirectWsdlStream { get; set; }
}