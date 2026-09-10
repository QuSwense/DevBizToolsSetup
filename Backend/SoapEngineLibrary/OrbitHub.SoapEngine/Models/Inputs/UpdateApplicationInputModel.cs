namespace OrbitHub.SoapEngine.Core.Models.Inputs;

/// <summary>
/// Base class for update-type application inputs.
/// Carries the application identifier and the updater actor identifier.
/// </summary>
public class UpdateApplicationInputModel : ApplicationMetadataInputModel
{
    public required int AppId { get; set; }
    public required string UpdatedBy { get; set; }
}