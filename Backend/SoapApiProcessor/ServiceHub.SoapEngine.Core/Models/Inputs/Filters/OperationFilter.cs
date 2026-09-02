namespace ServiceHub.SoapEngine.Core.Models.Inputs.Filters;

public class OperationFilter : PagedRequest
{
    public int? AppId { get; set; }
    public string? OperationName { get; set; }
    public bool? IsActive { get; set; }
}