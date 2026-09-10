namespace OrbitHub.SoapEngine.Core.Models.Inputs;

public class UpdateFullApplicationInputModel : UpdateApplicationInputModel
{
    public bool IsActive { get; set; } = true;
    public bool UpdateAuthentication { get; set; }
    public EAuthenticationType? AuthType { get; set; }
    public AuthCredentialsBaseInputModel? AuthCredentials { get; set; }
    public List<SaveOperationInputModel> Operations { get; set; } = [];
}