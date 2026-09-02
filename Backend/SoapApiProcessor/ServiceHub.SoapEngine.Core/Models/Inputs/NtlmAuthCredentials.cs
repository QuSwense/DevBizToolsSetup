using ServiceHub.SoapEngine.Core.Enums;

namespace ServiceHub.SoapEngine.Core.Models.Inputs;

public class NtlmAuthCredentials : AuthCredentialsBase
{
    public override EAuthenticationType AuthenticationType => EAuthenticationType.NTLM;
    public required string Username { get; set; }
    public required string Password { get; set; }
    public string? Domain { get; set; }
}