namespace ServiceHub.SoapEngine.Core.Enums;

/// <summary>
/// Execution status states for a SoapExecutionRun batch.
/// </summary>
public enum EExecutionStatus
{
    Pending = 1,
    InProgress = 2,
    Completed = 3,
    Failed = 4,
    Cancelled = 5
}
