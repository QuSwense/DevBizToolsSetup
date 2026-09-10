namespace OrbitHub.SoapEngine.Core.Models.Inputs;

/// <summary>
/// Base class for create-type application inputs.
/// Carries the actor identifier and optional direct WSDL stream.
/// </summary>
public class CreateApplicationInputModel : ApplicationMetadataInputModel
{
    public required string CreatedBy { get; set; }
    public Stream? DirectWsdlStream { get; set; }
}