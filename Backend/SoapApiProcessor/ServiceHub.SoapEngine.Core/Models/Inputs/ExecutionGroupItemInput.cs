namespace ServiceHub.SoapEngine.Core.Models.Inputs;

public class ExecutionGroupItemInput
{
    public required int RequestFileId { get; set; }
    public int? RequestFileHistoryId { get; set; } // Target specific historical version if desired
    public int ExecutionOrder { get; set; } = 1;
}
