using System.Text.Json.Serialization;
using ServiceHub.SoapEngine.Core.Enums;

namespace ServiceHub.SoapEngine.Core.Models.Inputs;

[JsonPolymorphic(TypeDiscriminatorPropertyName = "AuthenticationType")]
[JsonDerivedType(typeof(BasicAuthCredentials), nameof(EAuthenticationType.Basic))]
[JsonDerivedType(typeof(ApiKeyAuthCredentials), nameof(EAuthenticationType.APIKey))]
[JsonDerivedType(typeof(OAuth2Credentials), nameof(EAuthenticationType.OAuth2))]
[JsonDerivedType(typeof(NtlmAuthCredentials), nameof(EAuthenticationType.NTLM))]
public abstract class AuthCredentialsBase
{
    public abstract EAuthenticationType AuthenticationType { get; }
}