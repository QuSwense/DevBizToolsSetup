namespace ServiceHub.SoapEngine.Core.Exceptions;

/// <summary>
/// Thrown when WSDL retrieval, XML schema validation, or operation extraction fails.
/// </summary>
public class WsdlParsingException : SoapException
{
    public string? WsdlUrl { get; }

    public WsdlParsingException(string message)
        : base(message)
    {
    }

    public WsdlParsingException(string message, Exception innerException)
        : base(message, innerException)
    {
    }

    public WsdlParsingException(string message, string? wsdlUrl)
        : base(message)
    {
        WsdlUrl = wsdlUrl;
    }

    public WsdlParsingException(string message, string? wsdlUrl, Exception innerException)
        : base(message, innerException)
    {
        WsdlUrl = wsdlUrl;
    }
}