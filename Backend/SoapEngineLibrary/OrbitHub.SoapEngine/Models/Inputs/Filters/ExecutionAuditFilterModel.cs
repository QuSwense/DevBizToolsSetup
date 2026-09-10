namespace OrbitHub.SoapEngine.Core.Models.Inputs.Filters;

/// <summary>
/// Filter for paged queries against DirectExecutionAudit.
/// </summary>
public class ExecutionAuditFilterModel : PagedRequestModel
{
    public string? Name { get; set; }
    public string? ExecutionStatus { get; set; }
    public string? ExecutedBy { get; set; }
    public DateTime? ExecutedFrom { get; set; }
    public DateTime? ExecutedTo { get; set; }
}