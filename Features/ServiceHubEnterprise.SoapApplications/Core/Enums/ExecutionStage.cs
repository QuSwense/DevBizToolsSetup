using System.Text.Json.Serialization;

namespace ServiceHubEnterprise.SoapApplications.Core.Enums;

/// <summary>
/// Represents the current stage of a single SOAP request-file execution.
/// Serialized to/from camelCase string values (e.g. "buildingRequest") in
/// mock_db/Soap/soap-executions.json.
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
