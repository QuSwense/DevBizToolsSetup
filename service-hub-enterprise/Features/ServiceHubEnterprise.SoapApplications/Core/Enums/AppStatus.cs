using System.Text.Json.Serialization;

namespace ServiceHubEnterprise.SoapApplications.Core.Enums;

/// <summary>
/// Represents the operational status of a SOAP application.
/// Serialized to/from the "enabled"/"disabled" string values stored in mock_db/Soap/soap-apps.json.
/// </summary>
[JsonConverter(typeof(JsonStringEnumConverter))]
public enum AppStatus
{
    Enabled,
    Disabled
}
