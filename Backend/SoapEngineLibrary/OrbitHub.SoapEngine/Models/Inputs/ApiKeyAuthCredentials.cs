using ServiceHub.SoapEngine.Core.Enums;

namespace ServiceHub.SoapEngine.Core.Models.Inputs;

public class ApiKeyAuthCredentials : AuthCredentialsBase
{
    public override EAuthenticationType AuthenticationType => EAuthenticationType.APIKey;
    public required string HeaderName { get; set; }
    public required string ApiKey { get; set; }
    public bool SendInHeader { get; set; } = true;
}