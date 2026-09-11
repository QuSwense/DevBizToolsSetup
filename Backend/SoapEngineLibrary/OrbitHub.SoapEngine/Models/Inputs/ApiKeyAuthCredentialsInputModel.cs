using OrbitHub.GenericModels.Enums;

namespace OrbitHub.SoapEngine.Core.Models.Inputs;

public class ApiKeyAuthCredentialsInputModel : AuthCredentialsBaseInputModel
{
    public override EAuthenticationType AuthenticationType => EAuthenticationType.APIKey;
    public required string HeaderName { get; set; }
    public required string ApiKey { get; set; }
    public bool SendInHeader { get; set; } = true;
}