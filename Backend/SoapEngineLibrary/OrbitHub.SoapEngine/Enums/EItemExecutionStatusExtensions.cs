namespace ServiceHub.SoapEngine.Core.Enums;

public static class EItemExecutionStatusExtensions
{
    /// <summary>
    /// Converts the enum value to its corresponding database string representation.
    /// </summary>
    public static string ToDbString(this EItemExecutionStatus status) => status switch
    {
        EItemExecutionStatus.Pending => "Pending",
        EItemExecutionStatus.InProgress => "InProgress",
        EItemExecutionStatus.Success => "Success",
        EItemExecutionStatus.Failure => "Failure",
        EItemExecutionStatus.Skipped => "Skipped",
        _ => throw new ArgumentOutOfRangeException(nameof(status), status, null)
    };
}