namespace ServiceHub.SoapEngine.Core.Parsing.Models;

/// <summary>
/// Holds operation-level metadata parsed directly from WSDL binding definitions.
/// </summary>
public class ParsedOperationMetadata
{
    /// <summary>
    /// Gets or sets the operation name (e.g., GetCustomerDetails).
    /// </summary>
    public required string OperationName { get; set; }

    /// <summary>
    /// Gets or sets the SOAP Action URI specified in the binding.
    /// </summary>
    public string? SoapAction { get; set; }

    /// <summary>
    /// Gets or sets the root XML element name expected in the &lt;soap:Body&gt; for requests.
    /// </summary>
    public string? InputRootElementName { get; set; }

    /// <summary>
    /// Gets or sets the root XML element name returned in the &lt;soap:Body&gt; for responses.
    /// </summary>
    public string? OutputRootElementName { get; set; }
    public string? TargetNamespace { get; set; }
}