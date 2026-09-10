namespace OrbitHub.SoapEngine.Core.Models.Inputs;

public class ConfigureAuthInputModel
{
    public required int AppId { get; set; }
    public required AuthCredentialsBaseInputModel Credentials { get; set; }
    public required string ConfiguredBy { get; set; }
}