namespace OrbitHub.Data.Repositories.CoreManagement.Models;

public class UpdateGlobalSettingInput
{
    public int GlobalSettingId { get; set; }
    public string? Category { get; set; }
    public string? SettingKey { get; set; }
    public string? SettingValue { get; set; }
    public string? DataType { get; set; }
    public string? Description { get; set; }
    public bool? IsUserOverridable { get; set; }
    public bool? IsActive { get; set; }
    public string? UserId { get; set; }
}