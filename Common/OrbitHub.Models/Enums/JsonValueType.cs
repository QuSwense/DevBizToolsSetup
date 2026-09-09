namespace OrbitHub.Models.Enums;

/// <summary>
/// Defines the JSON value types used for indexing parsed JSON file element values.
/// Maps to CK_IndexingJsonFileElements_ValueType: 'String', 'Number', 'Boolean', 'Null', 'Array', 'Object'.
/// </summary>
public enum JsonValueType
{
    /// <summary>JSON string value.</summary>
    String = 0,

    /// <summary>JSON number value.</summary>
    Number = 1,

    /// <summary>JSON boolean value.</summary>
    Boolean = 2,

    /// <summary>JSON null value.</summary>
    Null = 3,

    /// <summary>JSON array value.</summary>
    Array = 4,

    /// <summary>JSON object value.</summary>
    Object = 5
}
