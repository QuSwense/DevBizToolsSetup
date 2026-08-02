using System.Text.Json.Serialization;

namespace ServiceHubEnterprise.SoapApplications.Core.Enums;

/// <summary>
/// Represents the authentication scheme used by a SOAP application.
/// Serialized to/from the string values stored in mock_db/Soap/soap-apps.json
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
