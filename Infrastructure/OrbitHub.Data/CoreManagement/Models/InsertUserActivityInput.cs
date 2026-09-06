namespace OrbitHub.Data.Repositories.CoreManagement.Models;

public class InsertUserActivityInput
{
    public string UserId { get; set; } = string.Empty;
    public string ActivityType { get; set; } = string.Empty;
    public string? ActionType { get; set; }
    public string? FeatureActivitiesJson { get; set; }
    public string? RelatedEntityType { get; set; }
    public Guid? RelatedEntityId { get; set; }
    public string? Notes { get; set; }
}