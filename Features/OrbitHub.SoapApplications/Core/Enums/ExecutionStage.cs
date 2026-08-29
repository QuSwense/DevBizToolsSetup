using System.Text.Json.Serialization;

namespace OrbitHub.SoapApplications.Core.Enums;

/// <summary>
/// Represents the current stage of a single SOAP request-file execution.
/// Serialized to/from camelCase string values (e.g. "buildingRequest") in
/// the database.
/// </summary>
[JsonConverter(typeof(JsonStringEnumConverter<ExecutionStage>))]
public enum ExecutionStage
{
    Queued,
    BuildingRequest,
    SendingRequest,
    AwaitingResponse,
    ParsingResponse,
    RunningTestCases,
    Complete
}
