namespace OrbitHub.GenericModels.Enums;

/// <summary>
/// Defines the element types used for file indexing.
/// Maps to stored procedure parameters: 'XML', 'JSON', 'PDF'.
/// </summary>
public enum EElementType
{
    /// <summary>XML file elements.</summary>
    XML = 0,

    /// <summary>JSON file elements.</summary>
    JSON = 1,

    /// <summary>PDF document elements.</summary>
    PDF = 2
}
