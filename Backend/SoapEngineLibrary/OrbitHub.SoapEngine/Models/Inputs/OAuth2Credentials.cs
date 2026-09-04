using ServiceHub.SoapEngine.Core.Enums;

namespace ServiceHub.SoapEngine.Core.Models.Inputs;

public class OAuth2Credentials : AuthCredentialsBase
{
    public override EAuthenticationType AuthenticationType => EAuthenticationType.OAuth2;
    public required string TokenEndpoint { get; set; }
    public required string ClientId { get; set; }
    public required string ClientSecret { get; set; }
    public string? Scope { get; set; }
    public string? GrantType { get; set; } = "client_credentials";
}