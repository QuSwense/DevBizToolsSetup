namespace OrbitHub.SoapEngine.Core.Models.Inputs;
/// <summary>
/// Represents a single SOAP operation definition supplied via UI.
/// </summary>
public class SaveOperationInputModel : OperationMetadataInputModel
{
    public int? Id { get; set; }
    public bool IsActive { get; set; } = true;
}
