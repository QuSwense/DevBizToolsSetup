namespace OrbitHub.SoapEngine.Core.Models.Inputs;

/// <summary>
/// Payload contract for creating an execution group run configuration.
/// </summary>
public class CreateExecutionGroupInputModel
{
    public int? AppId { get; set; }
    public required string GroupName { get; set; }
    public string? Description { get; set; }
    public required List<ExecutionGroupItemInputModel> Items { get; set; } = [];
    public required string CreatedBy { get; set; }
}
