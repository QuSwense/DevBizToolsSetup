namespace OrbitHub.Models.Models;

/// <summary>
/// Represents a permission grant to a specific user or role for a resource.
/// Shared pattern across ServiceAppPermissions, ServiceRequestFilesPermissions,
/// ServiceTestSuitesPermissions, ServiceTestCasesPermissions, and RuleSetsPermissions.
/// </summary>
public sealed record ResourcePermissionGrant
{
    /// <summary>The user ID this permission is granted to, or null if granted to a role.</summary>
    public string? UserId { get; init; }

    /// <summary>The role ID this permission is granted to, or null if granted to a user.</summary>
    public int? RoleId { get; init; }

    /// <summary>The resource permission identifier.</summary>
    public required string PermissionKey { get; init; }

    /// <summary>Whether the permission is granted (true) or denied (false).</summary>
    public bool IsGranted { get; init; } = true;

    /// <summary>Whether this permission grant is active.</summary>
    public bool IsActive { get; init; } = true;
}
