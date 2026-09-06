namespace OrbitHub.Data.Repositories.CoreManagement.Models;

public class UpdateGlobalSettingOutput
{
    public int? GlobalSettingId { get; set; }
    public Guid? PublicId { get; set; }
    public string? Category { get; set; }
    public string? SettingKey { get; set; }
    public string? SettingValue { get; set; }
    public string? DataType { get; set; }
    public string? Description { get; set; }
    public bool? IsUserOverridable { get; set; }
    public bool? IsActive { get; set; }
    public DateTime? CreatedAt { get; set; }
    public string? CreatedBy { get; set; }
    public DateTime? LastUpdatedAt { get; set; }
    public string? LastUpdatedBy { get; set; }
    public long? AuditActivityId { get; set; }
}