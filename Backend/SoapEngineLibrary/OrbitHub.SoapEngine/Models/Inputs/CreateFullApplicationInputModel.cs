using OrbitHub.GenericModels.Enums;

namespace OrbitHub.SoapEngine.Core.Models.Inputs;

public class CreateFullApplicationInputModel : CreateApplicationInputModel
{
    public bool IsActive { get; set; } = true;
    public EAuthenticationType? AuthType { get; set; }
    public AuthCredentialsBaseInputModel? AuthCredentials { get; set; }
    public List<SaveOperationInputModel> Operations { get; set; } = [];
}