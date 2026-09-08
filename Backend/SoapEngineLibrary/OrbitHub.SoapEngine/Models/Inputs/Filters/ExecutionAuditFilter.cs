namespace ServiceHub.SoapEngine.Core.Models.Inputs.Filters;

/// <summary>
/// Filter for paged queries against DirectExecutionAudit.
/// </summary>
public class ExecutionAuditFilter : PagedRequest
{
    public string? Name { get; set; }
    public string? ExecutionStatus { get; set; }
    public string? ExecutedBy { get; set; }
    public DateTime? ExecutedFrom { get; set; }
    public DateTime? ExecutedTo { get; set; }
}