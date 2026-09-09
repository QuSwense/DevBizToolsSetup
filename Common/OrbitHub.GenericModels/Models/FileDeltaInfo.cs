namespace OrbitHub.GenericModels.Models;

/// <summary>
/// Represents a file in a delta chain — either a base snapshot or a differential delta.
/// Used by ServiceRequestFiles and ServiceResponseFiles.
/// </summary>
public sealed record FileDeltaInfo
{
    /// <summary>True if this is a complete full payload snapshot; false for differential delta.</summary>
    public bool IsBaseSnapshot { get; init; } = true;

    /// <summary>The ID of the base snapshot this delta chain is rooted on, or null if this is itself the base.</summary>
    public int? ParentBaseId { get; init; }

    /// <summary>The ID of the immediate predecessor record in the delta chain, or null for base snapshots.</summary>
    public int? ParentDeltaId { get; init; }

    /// <summary>Depth count in the delta chain (0 for base snapshots, > 0 for incremental deltas).</summary>
    public int DeltaDepth { get; init; } = 0;
}
