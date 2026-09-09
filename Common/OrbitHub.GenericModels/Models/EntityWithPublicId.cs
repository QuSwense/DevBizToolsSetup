namespace OrbitHub.GenericModels.Models;

/// <summary>
/// Represents a base entity with a public unique identifier (GUID).
/// Most OrbitHub tables use PublicId for UI and secure operations.
/// </summary>
public abstract class EntityWithPublicId
{
    /// <summary>Public unique identifier for UI and secure operations.</summary>
    public Guid PublicId { get; init; } = Guid.NewGuid();
}
