namespace OrbitHub.SoapEngine.Core.Models.Inputs;

/// <summary>
/// Payload contract for uploading a request file stream to an operation.
/// </summary>
public class UploadRequestFileInputModel
{
    public required int OperationId { get; set; }
    public required string FileName { get; set; }
    public required Stream FileStream { get; set; }
    public required string CreatedBy { get; set; }
}
