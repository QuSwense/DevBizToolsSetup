namespace OrbitHub.Data.CoreManagement.Models;

public class UpdateUserSettingInput
{
    public int UserSettingId { get; set; }
    public int? GlobalSettingId { get; set; }
    public string? SettingValue { get; set; }
    public string? UserId { get; set; }
}