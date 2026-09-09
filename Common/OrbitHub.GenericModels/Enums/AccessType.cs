namespace OrbitHub.GenericModels.Enums;

/// <summary>
/// Defines the access types for permission-to-page mappings.
/// Maps to PermissionToUIPageMapping.AccessType: 'View', 'Edit', 'Full'.
/// </summary>
public enum AccessType
{
    /// <summary>View-only access to the resource.</summary>
    View = 0,

    /// <summary>Edit (read and write) access to the resource.</summary>
    Edit = 1,

    /// <summary>Full access including administration capabilities.</summary>
    Full = 2
}
