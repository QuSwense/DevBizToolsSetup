namespace ServiceHub.SoapEngine.Core.Models.Inputs.Filters;

public class RequestFileFilter : PagedRequest
{
    public int? OperationId { get; set; }
    public string? FileName { get; set; }
    public bool? IsActive { get; set; }
}