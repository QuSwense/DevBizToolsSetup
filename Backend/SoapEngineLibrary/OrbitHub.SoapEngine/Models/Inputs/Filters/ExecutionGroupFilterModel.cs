namespace OrbitHub.SoapEngine.Core.Models.Inputs.Filters;

public class ExecutionGroupFilterModel : PagedRequestModel
{
    public int? AppId { get; set; }
    public string? GroupName { get; set; }
    public bool? IsActive { get; set; }
}