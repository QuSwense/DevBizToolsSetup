using System.Text.Json.Serialization;

namespace OrbitHub.SoapApplications.Core.Enums;

/// <summary>
/// Represents the authentication scheme used by a SOAP application.
/// Serialized to/from the string values stored in the database
/// via <see cref="AuthTypeJsonConverter"/>.
/// </summary>
[JsonConverter(typeof(AuthTypeJsonConverter))]
public enum AuthType
{
    None,
    Basic,
    ApiKey,
    Bearer,
    Ntlm
}
