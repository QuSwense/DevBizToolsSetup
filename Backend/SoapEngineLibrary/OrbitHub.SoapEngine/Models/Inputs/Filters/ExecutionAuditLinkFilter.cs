namespace ServiceHub.SoapEngine.Core.Models.Inputs.Filters;

/// <summary>
/// Filter for paged queries against DirectExecutionAuditResponseFileLink.
/// </summary>
public class ExecutionAuditLinkFilter : PagedRequest
{
    public int? DirectExecutionAuditId { get; set; }
    public string? ExecutionStatus { get; set; }
}