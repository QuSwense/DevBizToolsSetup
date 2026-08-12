namespace ServiceHubEnterprise.Data.Models;

/// <summary>
/// Complete lifecycle status for any entity in the system
/// </summary>
public enum EEntityStatus
{
    /// <summary>
    /// Entity is active and fully operational
    /// </summary>
    Enabled = 0,
    
    /// <summary>
    /// Entity is temporarily suspended but can be re-enabled
    /// </summary>
    Disabled = 1,
    
    /// <summary>
    /// Entity is retired and read-only (soft delete)
    /// </summary>
    Archived = 2
}