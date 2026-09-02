namespace ServiceHub.SoapEngine.Core.Models.Inputs;

/// <summary>
/// Payload contract for triggering an execution run batch.
/// </summary>
public class ExecuteGroupRunInput
{
    public required int ExecutionGroupId { get; set; }
    public required string ExecutedBy { get; set; }
}