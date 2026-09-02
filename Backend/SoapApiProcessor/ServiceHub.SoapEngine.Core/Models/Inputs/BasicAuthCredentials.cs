using ServiceHub.SoapEngine.Core.Enums;

namespace ServiceHub.SoapEngine.Core.Models.Inputs;

public class BasicAuthCredentials : AuthCredentialsBase
{
    public override EAuthenticationType AuthenticationType => EAuthenticationType.Basic;
    public required string Username { get; set; }
    public required string Password { get; set; }
}