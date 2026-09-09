namespace OrbitHub.Models.Enums;

/// <summary>
/// Defines the file snapshot type for request/response file versioning.
/// Maps to IsBaseSnapshot column semantics and stored procedure output: 'Base', 'Delta'.
/// </summary>
public enum FileSnapshotType
{
    /// <summary>Complete full payload snapshot (base version).</summary>
    Base = 0,

    /// <summary>Incremental differential patch/delta.</summary>
    Delta = 1
}
