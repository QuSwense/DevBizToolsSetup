namespace ServiceHub.SoapEngine.Core.Models.Inputs;

/// <summary>
/// Payload contract for updating application metadata.
/// </summary>
public class EditApplicationInput : UpdateApplicationInput
{
    public string? Comment { get; set; }
}