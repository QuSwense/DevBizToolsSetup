namespace ServiceHub.SoapEngine.Core.Models.Inputs.Filters;

public class ApplicationFilter : PagedRequest
{
    public string? AppName { get; set; }
    public bool? IsActive { get; set; }
    public string? CreatedBy { get; set; }
    public DateTime? CreatedFrom { get; set; }
    public DateTime? CreatedTo { get; set; }
}