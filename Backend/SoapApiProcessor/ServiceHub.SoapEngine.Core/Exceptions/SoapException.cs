namespace ServiceHub.SoapEngine.Core.Exceptions;

/// <summary>
/// Base domain exception for all SOAP engine processing errors.
/// </summary>
public class SoapException : Exception
{
    public SoapException()
    {
    }

    public SoapException(string message)
        : base(message)
    {
    }

    public SoapException(string message, Exception innerException)
        : base(message, innerException)
    {
    }
}