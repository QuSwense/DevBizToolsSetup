namespace ServiceHub.SoapEngine.Core.Models.Outputs;

public record SoapExecutionResponse
{
    public required int HttpStatusCode { get; init; }
    public required string ResponseBody { get; init; }
    public required byte[] RawResponseBytes { get; init; }
    public required long LatencyMs { get; init; }
    public required bool IsSuccess { get; init; }
    public string? ContentType { get; init; }
}