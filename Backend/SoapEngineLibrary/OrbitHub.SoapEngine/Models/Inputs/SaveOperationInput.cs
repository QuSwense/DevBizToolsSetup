namespace ServiceHub.SoapEngine.Core.Models.Inputs;
/// <summary>
/// Represents a single SOAP operation definition supplied via UI.
/// </summary>
public class SaveOperationInput : OperationMetadata
{
    public int? Id { get; set; }
    public bool IsActive { get; set; } = true;
}
