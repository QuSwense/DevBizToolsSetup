namespace OrbitHub.SoapEngine.Core.Models.Inputs.Filters;

public class OperationFilterModel : PagedRequestModel
{
    public int? AppId { get; set; }
    public string? OperationName { get; set; }
    public bool? IsActive { get; set; }
}