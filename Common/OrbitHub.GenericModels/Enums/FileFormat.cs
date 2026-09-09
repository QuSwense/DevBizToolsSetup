namespace OrbitHub.GenericModels.Enums;

/// <summary>
/// Defines the file format types used for request and response files.
/// Maps to CK_ServiceRequestFiles_Format / CK_ServiceResponseFiles_Format / CK_BinaryEmbeddingsStore_Format:
/// 'XML', 'JSON', 'PDF', 'BINARY'.
/// </summary>
public enum FileFormat
{
    /// <summary>XML (Extensible Markup Language) format.</summary>
    XML = 0,

    /// <summary>JSON (JavaScript Object Notation) format.</summary>
    JSON = 1,

    /// <summary>PDF (Portable Document Format).</summary>
    PDF = 2,

    /// <summary>Binary format (arbitrary binary data).</summary>
    BINARY = 3
}
