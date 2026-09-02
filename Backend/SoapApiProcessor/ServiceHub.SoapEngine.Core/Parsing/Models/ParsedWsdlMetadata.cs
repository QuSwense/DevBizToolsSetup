namespace ServiceHub.SoapEngine.Core.Parsing.Models;

/// <summary>
/// Container holding parsed operations, extracted XSD schemas, namespaces, and raw WSDL XML content.
/// </summary>
public class ParsedWsdlMetadata
{
    /// <summary>
    /// Gets or sets the list of SOAP operations extracted from the WSDL bindings.
    /// </summary>
    public List<ParsedOperationMetadata> Operations { get; set; } = [];

    /// <summary>
    /// Gets or sets the key-value dictionary of XML namespace prefixes to URIs.
    /// </summary>
    public Dictionary<string, string> Namespaces { get; set; } = new();

    /// <summary>
    /// Gets or sets isolated XSD schema strings extracted from &lt;wsdl:types&gt;.
    /// </summary>
    public List<string> ExtractedXsdSchemas { get; set; } = [];

    /// <summary>
    /// Gets or sets the full raw WSDL XML content.
    /// </summary>
    public required string RawWsdlContent { get; set; }
    public string? TargetNamespace { get; set; }
}