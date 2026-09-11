using OrbitHub.GenericModels.Enums;

namespace OrbitHub.SoapEngine.Core.Models.Inputs;

public class NtlmAuthCredentialsInputModel : AuthCredentialsBaseInputModel
{
    public override EAuthenticationType AuthenticationType => EAuthenticationType.NTLM;
    public required string Username { get; set; }
    public required string Password { get; set; }
    public string? Domain { get; set; }
}