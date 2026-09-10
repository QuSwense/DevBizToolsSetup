namespace ServiceHub.SoapEngine.Core.Models.Inputs;

/// <summary>
/// Payload contract for creating an execution group run configuration.
/// </summary>
public class CreateExecutionGroupInput
{
    public int? AppId { get; set; }
    public required string GroupName { get; set; }
    public string? Description { get; set; }
    public required List<ExecutionGroupItemInput> Items { get; set; } = [];
    public required string CreatedBy { get; set; }
}
