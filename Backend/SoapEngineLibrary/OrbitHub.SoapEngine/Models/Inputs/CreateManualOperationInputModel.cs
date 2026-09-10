namespace OrbitHub.SoapEngine.Core.Models.Inputs;

/// <summary>
/// Input model to manually define a SOAP Operation without a WSDL file.
/// </summary>
public class CreateManualOperationInputModel : OperationMetadataInputModel
{
    public required int AppId { get; set; }
    public required string CreatedBy { get; set; }
}