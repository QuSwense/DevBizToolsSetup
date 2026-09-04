namespace ServiceHub.SoapEngine.Core.Enums;

public static class EExecutionStatusExtensions
{
    /// <summary>
    /// Converts the enum value to its corresponding database string representation.
    /// </summary>
    public static string ToDbString(this EExecutionStatus status) => status switch
    {
        EExecutionStatus.Pending => "Pending",
        EExecutionStatus.InProgress => "InProgress",
        EExecutionStatus.Completed => "Completed",
        EExecutionStatus.Failed => "Failed",
        EExecutionStatus.Cancelled => "Cancelled",
        _ => throw new ArgumentOutOfRangeException(nameof(status), status, null)
    };
}