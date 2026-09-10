namespace ServiceHub.SoapEngine.Core.Models.Inputs;

/// <summary>
/// Payload contract for syncing WSDL from a remote URL or direct file stream.
/// </summary>
public class SyncWsdlInput
{
    public required int AppId { get; set; }
    public string? WsdlUrl { get; set; }
    public Stream? WsdlFileStream { get; set; }
    public string? WsdlFileName { get; set; }
    public required string SyncedBy { get; set; }
    public string? ChangeComment { get; set; }
}