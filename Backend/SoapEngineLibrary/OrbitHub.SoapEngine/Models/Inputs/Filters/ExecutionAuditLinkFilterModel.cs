namespace OrbitHub.SoapEngine.Core.Models.Inputs.Filters;

/// <summary>
/// Filter for paged queries against DirectExecutionAuditResponseFileLink.
/// </summary>
public class ExecutionAuditLinkFilterModel : PagedRequestModel
{
    public int? DirectExecutionAuditId { get; set; }
    public string? ExecutionStatus { get; set; }
}