namespace OrbitHub.SoapEngine.Core.Models.Inputs;

public class BasicAuthCredentialsInputModel : AuthCredentialsBaseInputModel
{
    public override EAuthenticationType AuthenticationType => EAuthenticationType.Basic;
    public required string Username { get; set; }
    public required string Password { get; set; }
}