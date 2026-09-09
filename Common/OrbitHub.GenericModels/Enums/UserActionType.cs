namespace OrbitHub.GenericModels.Enums;

/// <summary>
/// Defines granular user action types for activity logging.
/// Maps to UserActivities.ActionType: 'Click', 'View', 'Edit'.
/// </summary>
public enum UserActionType
{
    /// <summary>User clicked on an element.</summary>
    Click = 0,

    /// <summary>User viewed a resource or page.</summary>
    View = 1,

    /// <summary>User edited a resource.</summary>
    Edit = 2
}
