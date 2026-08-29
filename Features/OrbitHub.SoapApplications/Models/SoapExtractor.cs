namespace OrbitHub.SoapApplications.Models;

/// <summary>
/// A single extraction definition inside a test case. It pulls a value out of
/// the request or response payload (XML via XPath, JSON via JSON path, or a
/// simulated PDF text/field extraction) and optionally asserts it equals
/// <see cref="ExpectedValue"/>.
/// </summary>
public class SoapExtractor
{
    public string Id { get; set; } = "";

    /// <summary>Human-readable name shown in the extraction results.</summary>
    public string Name { get; set; } = "";

    /// <summary>Payload to read from: "request" or "response".</summary>
    public string Source { get; set; } = "response";

    /// <summary>Extractor type: "xpath" | "jsonpath" | "pdf".</summary>
    public string Type { get; set; } = "xpath";

    /// <summary>
    /// XPath expression (XML), JSON path (JSON) or field label (PDF) used to locate the value.
    /// </summary>
    public string Path { get; set; } = "";

    /// <summary>
    /// Optional expected value. When set, the extraction is treated as an assertion
    /// (passed when the extracted value matches). When null, the extraction is informational only.
    /// </summary>
    public string? ExpectedValue { get; set; }
}
