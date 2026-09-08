using ServiceHub.SoapEngine.Core.Enums;

namespace ServiceHub.SoapEngine.Core.Models.Inputs;

public class CreateFullApplicationInput : CreateApplicationInput
{
    public bool IsActive { get; set; } = true;
    public EAuthenticationType? AuthType { get; set; }
    public AuthCredentialsBase? AuthCredentials { get; set; }
    public List<SaveOperationInput> Operations { get; set; } = [];
}