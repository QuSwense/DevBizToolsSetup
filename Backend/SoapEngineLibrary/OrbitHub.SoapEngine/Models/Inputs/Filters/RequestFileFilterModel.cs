namespace OrbitHub.SoapEngine.Core.Models.Inputs.Filters;

public class RequestFileFilterModel : PagedRequestModel
{
    public int? OperationId { get; set; }
    public string? FileName { get; set; }
    public bool? IsActive { get; set; }
}