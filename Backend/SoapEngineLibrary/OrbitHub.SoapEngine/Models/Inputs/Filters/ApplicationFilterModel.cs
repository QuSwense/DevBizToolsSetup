namespace OrbitHub.SoapEngine.Core.Models.Inputs.Filters;

public class ApplicationFilterModel : PagedRequestModel
{
    public string? AppName { get; set; }
    public bool? IsActive { get; set; }
    public string? CreatedBy { get; set; }
    public DateTime? CreatedFrom { get; set; }
    public DateTime? CreatedTo { get; set; }
}