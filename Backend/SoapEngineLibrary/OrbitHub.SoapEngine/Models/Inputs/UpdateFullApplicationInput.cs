using ServiceHub.SoapEngine.Core.Enums;

namespace ServiceHub.SoapEngine.Core.Models.Inputs;

public class UpdateFullApplicationInput : UpdateApplicationInput
{
    public bool IsActive { get; set; } = true;
    public bool UpdateAuthentication { get; set; }
    public EAuthenticationType? AuthType { get; set; }
    public AuthCredentialsBase? AuthCredentials { get; set; }
    public List<SaveOperationInput> Operations { get; set; } = [];
}