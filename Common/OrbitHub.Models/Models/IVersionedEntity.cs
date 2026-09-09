namespace OrbitHub.Models.Models;

/// <summary>
/// Represents a versioned record with optimistic concurrency control.
/// RecordVersion format: YY.QQ.NN (e.g., "26.03.01").
/// </summary>
public interface IVersionedEntity
{
    /// <summary>Record version for optimistic concurrency control, formatted as YY.QQ.NN.</summary>
    string RecordVersion { get; }
}
