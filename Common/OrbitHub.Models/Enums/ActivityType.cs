namespace OrbitHub.Models.Enums;

/// <summary>
/// Defines the types of user activities tracked in audit logs.
/// Maps to UserActivities.ActivityType: 'Login', 'FeatureUsage'.
/// </summary>
public enum ActivityType
{
    /// <summary>User login activity.</summary>
    Login = 0,

    /// <summary>User feature/interaction usage activity.</summary>
    FeatureUsage = 1
}
