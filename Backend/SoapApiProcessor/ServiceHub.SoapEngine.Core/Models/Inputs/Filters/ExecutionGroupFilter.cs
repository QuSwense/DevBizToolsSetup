namespace ServiceHub.SoapEngine.Core.Models.Inputs.Filters;

public class ExecutionGroupFilter : PagedRequest
{
    public int? AppId { get; set; }
    public string? GroupName { get; set; }
    public bool? IsActive { get; set; }
}