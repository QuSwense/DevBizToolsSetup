using ServiceHub.SoapEngine.Core.Enums;

namespace ServiceHub.SoapEngine.Core.Models.Inputs;

public class UpdateFullApplicationInput
{
    public required int AppId { get; set; }
    public required string AppName { get; set; }
    public required string BaseUrl { get; set; }
    public string? WsdlRelativeUrl { get; set; }
    public string? HealthcheckRelativeUrl { get; set; }
    public string? Description { get; set; }
    public bool IsActive { get; set; } = true;
    public required string UpdatedBy { get; set; }
    public bool UpdateAuthentication { get; set; }
    public EAuthenticationType? AuthType { get; set; }
    public AuthCredentialsBase? AuthCredentials { get; set; }   // changed
    public List<SaveOperationInput> Operations { get; set; } = [];
}