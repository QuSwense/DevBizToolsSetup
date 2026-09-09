namespace OrbitHub.GenericModels.Enums;

/// <summary>
/// Defines the available system role names.
/// Maps to Seeds/RolesSeed.sql: 'Developer', 'Admin', 'Viewer'.
/// </summary>
public enum ESystemRoleName
{
    /// <summary>Developer role — full access to all resources including settings.</summary>
    Developer = 0,

    /// <summary>Administrator role — full access to main resource topics (excludes settings/system).</summary>
    Admin = 1,

    /// <summary>Viewer role — read-only access to all resources.</summary>
    Viewer = 2
}
