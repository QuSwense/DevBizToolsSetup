using System.Text.Json.Serialization;
using OrbitHub.GenericModels.Enums;

namespace OrbitHub.SoapEngine.Core.Models.Inputs;

[JsonPolymorphic(TypeDiscriminatorPropertyName = nameof(AuthenticationType))]
[JsonDerivedType(typeof(BasicAuthCredentialsInputModel), nameof(EAuthenticationType.Basic))]
[JsonDerivedType(typeof(ApiKeyAuthCredentialsInputModel), nameof(EAuthenticationType.APIKey))]
[JsonDerivedType(typeof(OAuth2CredentialsInputModel), nameof(EAuthenticationType.OAuth2))]
[JsonDerivedType(typeof(NtlmAuthCredentialsInputModel), nameof(EAuthenticationType.NTLM))]
public abstract class AuthCredentialsBaseInputModel
{
    public abstract EAuthenticationType AuthenticationType { get; }
}