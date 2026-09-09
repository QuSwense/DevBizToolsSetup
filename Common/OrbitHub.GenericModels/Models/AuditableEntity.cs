namespace OrbitHub.GenericModels.Models;

/// <summary>
/// Represents an audit-trail base record with common timestamp and user tracking columns.
/// Shared pattern across all OrbitHub tables.
/// </summary>
public abstract class AuditableEntityModel
{
    /// <summary>Timestamp when the record was created.</summary>
    public DateTime CreatedAt { get; init; } = DateTime.UtcNow;

    /// <summary>User ID who created the record.</summary>
    public string? CreatedBy { get; init; }

    /// <summary>Timestamp when the record was last updated, or null if never updated.</summary>
    public DateTime? LastUpdatedAt { get; set; }

    /// <summary>User ID who last updated the record, or null if never updated.</summary>
    public string? LastUpdatedBy { get; set; }
}
