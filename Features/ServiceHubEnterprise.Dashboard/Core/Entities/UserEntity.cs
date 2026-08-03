namespace ServiceHubEnterprise.Dashboard.Core.Entities;

/// <summary>
/// Represents a user of the application.
/// </summary>
public sealed class UserEntity
{
    public string Name { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
}
