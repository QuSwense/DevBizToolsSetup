namespace OrbitHub.SoapEngine.Core.Models.Inputs;

/// <summary>
/// Payload contract for updating application metadata.
/// </summary>
public class EditApplicationInputModel : UpdateApplicationInputModel
{
    public string? Comment { get; set; }
}