namespace ServiceHub.SoapEngine.Core.Models.Inputs.Filters;

public class ExecutionRunFilter : PagedRequest
{
    public int? ExecutionGroupId { get; set; }
    public string? RunStatus { get; set; }
    public string? ExecutedBy { get; set; }
    public DateTime? StartedFrom { get; set; }
    public DateTime? StartedTo { get; set; }
}