namespace OrbitHub.SoapApplications.Models;

/// <summary>
/// A field/value pair parsed out of a request or response payload so it can be
/// surfaced separately for easy visibility and testing. Embedded fields (e.g.
/// base64 blobs) are flagged and given a decoded preview.
/// </summary>
public class SoapParsedField
{
    /// <summary>Display name of the field (usually the XML/JSON element name).</summary>
    public string Name { get; set; } = "";

    /// <summary>Source of the field: "request" or "response".</summary>
    public string Source { get; set; } = "response";

    /// <summary>Path used to locate the field (XPath / JSON path / element path).</summary>
    public string Path { get; set; } = "";

    /// <summary>Raw value of the field.</summary>
    public string Value { get; set; } = "";

    /// <summary>True when the value is an embedded blob (e.g. base64-encoded content).</summary>
    public bool IsEmbedded { get; set; }

    /// <summary>Decoded/truncated preview of an embedded value (null when not embedded).</summary>
    public string? DecodedPreview { get; set; }
}
