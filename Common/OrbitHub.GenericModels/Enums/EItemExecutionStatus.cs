namespace OrbitHub.GenericModels.Enums;

/// <summary>
/// Execution status states for an individual SoapExecutionItemRun.
/// </summary>
public enum EItemExecutionStatus
{
    Pending = 1,
    InProgress = 2,
    Success = 3,
    Failure = 4,
    Skipped = 5
}
