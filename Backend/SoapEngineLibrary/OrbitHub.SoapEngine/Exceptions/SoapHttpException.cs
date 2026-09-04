namespace ServiceHub.SoapEngine.Core.Exceptions;

using System.Net;

/// <summary>
/// Thrown when an HTTP transport error occurs during outbound SOAP requests.
/// </summary>
public class SoapHttpException : SoapException
{
    public HttpStatusCode? HttpStatusCode { get; }
    public string? ResponseBody { get; }
    public string? TargetUrl { get; }

    public SoapHttpException(string message)
        : base(message)
    {
    }

    public SoapHttpException(string message, HttpStatusCode statusCode, string? responseBody, string? targetUrl)
        : base(message)
    {
        HttpStatusCode = statusCode;
        ResponseBody = responseBody;
        TargetUrl = targetUrl;
    }

    public SoapHttpException(string message, HttpStatusCode statusCode, string? responseBody, string? targetUrl, Exception innerException)
        : base(message, innerException)
    {
        HttpStatusCode = statusCode;
        ResponseBody = responseBody;
        TargetUrl = targetUrl;
    }
}