namespace OrbitHub.SoapEngine.Core.Models.Inputs;

/// <summary>
/// Payload contract for uploading multiple request files in bulk.
/// </summary>
public class BatchUploadRequestFilesInputModel
{
    public required int AppId { get; set; }
    public required List<UploadRequestFileInputModel> RequestFiles { get; set; } = [];
    public required string UploadedBy { get; set; }
}