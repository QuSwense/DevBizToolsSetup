namespace OrbitHub.Models.Enums;

/// <summary>
/// Defines the data types supported for global and user settings values.
/// Maps to CK_GlobalSettings_DataType: 'String', 'Integer', 'Decimal', 'Boolean', 'Json', 'Xml', 'DateTime'.
/// </summary>
public enum SettingDataType
{
    /// <summary>String value.</summary>
    String = 0,

    /// <summary>Integer (whole number) value.</summary>
    Integer = 1,

    /// <summary>Decimal (floating-point) value.</summary>
    Decimal = 2,

    /// <summary>Boolean (true/false) value.</summary>
    Boolean = 3,

    /// <summary>JSON (JavaScript Object Notation) value.</summary>
    Json = 4,

    /// <summary>XML (Extensible Markup Language) value.</summary>
    Xml = 5,

    /// <summary>DateTime value.</summary>
    DateTime = 6
}
