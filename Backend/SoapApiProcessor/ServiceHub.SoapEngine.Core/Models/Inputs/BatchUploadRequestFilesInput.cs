namespace ServiceHub.SoapEngine.Core.Models.Inputs;

/// <summary>
/// Payload contract for uploading multiple request files in bulk.
/// </summary>
public class BatchUploadRequestFilesInput
{
    public required int AppId { get; set; }
    public required List<UploadRequestFileInput> RequestFiles { get; set; } = [];
    public required string UploadedBy { get; set; }
}