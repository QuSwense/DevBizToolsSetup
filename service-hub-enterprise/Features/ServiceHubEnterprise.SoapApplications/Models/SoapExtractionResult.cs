namespace ServiceHubEnterprise.SoapApplications.Models;

/// <summary>
/// The outcome of running a single <see cref="SoapExtractor"/> against a
/// request/response payload during an execution.
/// </summary>
public class SoapExtractionResult
{
    public string ExtractorId { get; set; } = "";

    /// <summary>Name copied from the extractor for standalone display.</summary>
    public string Name { get; set; } = "";

    /// <summary>Payload source: "request" or "response".</summary>
    public string Source { get; set; } = "response";

    /// <summary>Extractor type: "xpath" | "jsonpath" | "pdf".</summary>
    public string Type { get; set; } = "xpath";

    /// <summary>Path expression that was evaluated.</summary>
    public string Path { get; set; } = "";

    /// <summary>Extracted value (empty when nothing matched).</summary>
    public string Value { get; set; } = "";

    /// <summary>Expected value from the extractor (null when informational only).</summary>
    public string? Expected { get; set; }

    /// <summary>True when an expected value was configured.</summary>
    public bool HasExpected { get; set; }

    /// <summary>
    /// Assertion outcome. Always true for informational extractions (no expected value).
    /// </summary>
    public bool Passed { get; set; }
}
