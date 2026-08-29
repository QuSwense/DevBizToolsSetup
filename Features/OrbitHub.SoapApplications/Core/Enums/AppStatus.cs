using System.Text.Json.Serialization;

namespace OrbitHub.SoapApplications.Core.Enums;

/// <summary>
/// Represents the operational status of a SOAP application.
/// Serialized to/from the "enabled"/"disabled" string values stored in the database.
/// </summary>
[JsonConverter(typeof(JsonStringEnumConverter))]
public enum AppStatus
{
    Enabled,
    Disabled
}
