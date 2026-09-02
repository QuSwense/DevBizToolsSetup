using ServiceHub.SoapEngine.Core.Enums;

namespace ServiceHub.SoapEngine.Core.Models.Inputs;

public class ConfigureAuthInput
{
    public required int AppId { get; set; }
    public required AuthCredentialsBase Credentials { get; set; }
    public required string ConfiguredBy { get; set; }
}