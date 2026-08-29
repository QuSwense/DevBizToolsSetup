namespace OrbitHub.FileManagement.Core.Enums;

/// <summary>
/// Represents the type of a file managed by the File Management feature.
/// </summary>
public enum FileType
{
    /// <summary>JSON file (.json)</summary>
    Json,

    /// <summary>XML file (.xml)</summary>
    Xml,

    /// <summary>Plain text file (.txt, .csv, etc.)</summary>
    PlainText,

    /// <summary>PDF document (.pdf)</summary>
    Pdf,

    /// <summary>WSDL definition (.wsdl)</summary>
    Wsdl,

    /// <summary>Other / unknown file type</summary>
    Other
}