using OrbitHub.GenericModels.Enums;

namespace OrbitHub.SoapEngine.Core.Models.Inputs;

public class OAuth2CredentialsInputModel : AuthCredentialsBaseInputModel
{
    public override EAuthenticationType AuthenticationType => EAuthenticationType.OAuth2;
    public required string TokenEndpoint { get; set; }
    public required string ClientId { get; set; }
    public required string ClientSecret { get; set; }
    public string? Scope { get; set; }
    public string? GrantType { get; set; } = "client_credentials";
}