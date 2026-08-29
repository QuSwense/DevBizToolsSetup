namespace OrbitHub.Dashboard.Application.DTOs;

/// <summary>
/// Data transfer object for an application user.
/// </summary>
public sealed class UserDto
{
    public string Name { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
}
