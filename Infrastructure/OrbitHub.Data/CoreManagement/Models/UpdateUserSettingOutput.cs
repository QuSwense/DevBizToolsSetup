namespace OrbitHub.Data.Repositories.CoreManagement.Models;

public class UpdateUserSettingOutput
{
    public int? UserSettingId { get; set; }
    public Guid? PublicId { get; set; }
    public int? GlobalSettingId { get; set; }
    public string? UserId { get; set; }
    public string? SettingValue { get; set; }
    public DateTime? LastUpdatedAt { get; set; }
    public string? SettingKey { get; set; }
    public long? AuditActivityId { get; set; }
}