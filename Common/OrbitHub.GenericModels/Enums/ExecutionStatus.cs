namespace OrbitHub.GenericModels.Enums;

/// <summary>
/// Defines the execution status for test suite and test case executions.
/// Maps to CK_ServiceTestSuiteExecutionAuditTestCaseLinks_ExecutionStatus:
/// 'Pending', 'InProgress', 'Completed', 'Failed'.
/// </summary>
public enum ExecutionStatus
{
    /// <summary>Execution is queued and pending start.</summary>
    Pending = 0,

    /// <summary>Execution is currently running.</summary>
    InProgress = 1,

    /// <summary>Execution completed successfully.</summary>
    Completed = 2,

    /// <summary>Execution failed with errors.</summary>
    Failed = 3
}
